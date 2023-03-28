defmodule MonexApi.Transaction.GetTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.{Error, Repo, Transaction, User}

  import MonexApi.Factory

  describe "by_id/2" do
    setup do
      %User{id: id_user1} = build(:user_params) |> User.changeset_create() |> Repo.insert!()

      %User{id: id_user2} =
        build(:user_params, %{"email" => "some2@gmail.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %Transaction{id: id_transaction} =
        build(:transaction_params, %{"from_user" => id_user1, "to_user" => id_user2})
        |> Transaction.changeset()
        |> Repo.insert!()

      %{
        id_user: id_user1,
        id_transaction: id_transaction
      }
    end

    test "when transacion and user id are valid, should return the transaction", %{
      id_user: id_user,
      id_transaction: id_transaction
    } do
      result = Transaction.Get.by_id(id_transaction, id_user)

      assert %Transaction{} = result
    end

    test "when transaction or user id are invalid, should return the error", %{
      id_user: id_user,
      id_transaction: id_transaction
    } do
      result_with_invalid_transaction_id = Transaction.Get.by_id(Ecto.UUID.generate(), id_user)
      result_with_invalid_user_id = Transaction.Get.by_id(id_transaction, Ecto.UUID.generate())

      expected_result = %Error{
        result: "transaction is not found",
        status: :bad_request
      }

      assert expected_result == result_with_invalid_transaction_id
      assert expected_result == result_with_invalid_user_id
    end
  end

  describe "by_user_id/2" do
    setup do
      %User{id: id_user1} = build(:user_params) |> User.changeset_create() |> Repo.insert!()

      %User{id: id_user2} =
        build(:user_params, %{"email" => "some2@gmail.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %Transaction{} =
        build(:transaction_params, %{"from_user" => id_user1, "to_user" => id_user2})
        |> Transaction.changeset()
        |> Repo.insert!()

      %Transaction{} =
        build(:transaction_params, %{"from_user" => id_user2, "to_user" => id_user1})
        |> Transaction.changeset()
        |> Repo.insert!()

      %{id_user: id_user1}
    end

    test "when user id are valid, should return map with transactions", %{id_user: id_user1} do
      result = Transaction.Get.by_user_id(id_user1, 1)

      assert %{
               next_page: 2,
               page: 1,
               previous_page: 1,
               quantity: 2,
               transactions: [%Transaction{}, _]
             } = result
    end

    test "when user id are invalid, should return map with empty transactions list" do
      result = Transaction.Get.by_user_id(Ecto.UUID.generate(), 1)

      assert %{
               next_page: 2,
               page: 1,
               previous_page: 1,
               quantity: 0,
               transactions: []
             } = result
    end
  end
end
