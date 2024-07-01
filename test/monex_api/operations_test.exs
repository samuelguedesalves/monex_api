defmodule MonexApi.OperationsTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.Operations
  alias MonexApi.Operations.Transaction
  alias MonexApi.Repo
  alias MonexApi.Users.User

  import MonexApi.Factory

  describe "get_transaction_by_id/2" do
    setup do
      %User{id: id_user01} =
        build(:user_params, %{email: "user01@email.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %User{id: id_user02} =
        build(:user_params, %{email: "user02@email.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %Transaction{id: id_transaction} =
        build(:transaction_params, %{from_user: id_user01, to_user: id_user02})
        |> Transaction.changeset()
        |> Repo.insert!()

      %{id_user: id_user01, id_transaction: id_transaction}
    end

    test "when transacion and user id are valid, should return the transaction", %{
      id_user: id_user,
      id_transaction: id_transaction
    } do
      assert {:ok, %Transaction{} = transaction} =
               Operations.get_transaction_by_id(id_transaction, id_user)

      assert transaction.id == id_transaction
    end

    test "when transaction or user id are invalid, should return the error", %{
      id_user: id_user,
      id_transaction: id_transaction
    } do
      invalid_transaction_id = 99
      invalid_user_id = 99

      result_with_invalid_transaction_id =
        Operations.get_transaction_by_id(invalid_transaction_id, id_user)

      result_with_invalid_user_id =
        Operations.get_transaction_by_id(id_transaction, invalid_user_id)

      expected_result = {:error, "transaction is not found"}

      assert expected_result == result_with_invalid_transaction_id
      assert expected_result == result_with_invalid_user_id
    end
  end

  describe "list_transactions_by_user_id/2" do
    setup do
      %User{id: id_user01} =
        build(:user_params, %{email: "user01@email.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %User{id: id_user02} =
        build(:user_params, %{email: "user02@email.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %Transaction{} =
        build(:transaction_params, %{from_user: id_user01, to_user: id_user02})
        |> Transaction.changeset()
        |> Repo.insert!()

      %Transaction{} =
        build(:transaction_params, %{from_user: id_user02, to_user: id_user01})
        |> Transaction.changeset()
        |> Repo.insert!()

      %{id_user: id_user01}
    end

    test "when user id are valid, should return map with transactions", %{id_user: id_user1} do
      page = 1

      assert {:ok, data} = Operations.list_transactions_by_user_id(id_user1, page)

      assert %{
               next_page: 2,
               page: 1,
               previous_page: 1,
               quantity: 2,
               transactions: [%Transaction{}, _]
             } = data
    end

    test "when user id are invalid, should return map with empty transactions list" do
      invalid_user_id = 99
      page = 1

      {:ok, data} = Operations.list_transactions_by_user_id(invalid_user_id, page)

      assert %{
               next_page: 2,
               page: 1,
               previous_page: 1,
               quantity: 0,
               transactions: []
             } = data
    end
  end

  describe "create_transaction/1" do
    setup do
      {:ok, sender_user} =
        build(:user_params, %{email: "sender.user@email.com"})
        |> User.changeset_create()
        |> Repo.insert()

      {:ok, receiver_user} =
        build(:user_params, %{email: "receiver.user@email.com"})
        |> User.changeset_create()
        |> Repo.insert()

      %{sender_user: sender_user, receiver_user: receiver_user}
    end

    test "when all params are valid, should return a valid transaction struct", %{
      sender_user: sender_user,
      receiver_user: receiver_user
    } do
      params = %{
        amount: 1000,
        user_id: receiver_user.id
      }

      assert {:ok, %Transaction{} = transaction} =
               Operations.create_transaction(sender_user, params)

      assert transaction.amount == params.amount
      assert transaction.from_user == sender_user.id
      assert transaction.to_user == receiver_user.id
    end

    test "when receiver user id are invalid, should return a error struct with changeset", %{
      sender_user: sender_user
    } do
      invalid_receiver_user_id = 99

      params = %{
        amount: 1000,
        user_id: invalid_receiver_user_id
      }

      assert {:error, "sender user not found"} ==
               Operations.create_transaction(sender_user, params)
    end

    test "when amount param not is positive, should return a error struct with changeset", %{
      sender_user: sender_user,
      receiver_user: receiver_user
    } do
      params = %{
        amount: 0,
        user_id: receiver_user.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Operations.create_transaction(sender_user, params)

      expected_changeset_errors = %{amount: ["amount must be positive"]}

      assert errors_on(changeset) == expected_changeset_errors
    end
  end
end
