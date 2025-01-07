defmodule MonexWeb.Schema.OperationsTest do
  use MonexWeb.ConnCase, async: false

  alias Monex.Operations.Transaction
  alias Monex.Repo
  alias Monex.Users.User

  import Monex.Factory

  @transactions_from_user """
  query transactionsFromUser($page: Int!) {
    transactionsFromUser(page: $page) {
      transactions {
        id
        amount
        from_user
        to_user
        processed_at
      }
      page
      quantity
      next_page
      previous_page
    }
  }
  """

  describe "query: transactions_from_user" do
    setup do
      {:ok, sender_user} =
        build(:user_params, %{email: "sender@email.com"})
        |> User.changeset_create()
        |> Repo.insert()

      {:ok, receiver_user} =
        build(:user_params, %{email: "receiver@email.com"})
        |> Monex.Users.create_user()

      {:ok, _transaction01} =
        build(:transaction_params, %{from_user: sender_user.id, to_user: receiver_user.id})
        |> Transaction.changeset()
        |> Repo.insert()

      {:ok, _transaction02} =
        build(:transaction_params, %{from_user: receiver_user.id, to_user: sender_user.id})
        |> Transaction.changeset()
        |> Repo.insert()

      {:ok, _transaction03} =
        build(:transaction_params, %{from_user: sender_user.id, to_user: receiver_user.id})
        |> Transaction.changeset()
        |> Repo.insert()

      %{user: sender_user}
    end

    test "when list works", %{conn: conn, user: user} do
      assert {:ok, response} =
               conn
               |> authenticated(user)
               |> run_graphql(@transactions_from_user, %{page: 1})

      assert %{
               "transactionsFromUser" => %{
                 "next_page" => 2,
                 "page" => 1,
                 "previous_page" => 1,
                 "quantity" => 3,
                 "transactions" => transactions
               }
             } = response

      assert length(transactions) == 3

      assert [
               %{
                 "amount" => _,
                 "from_user" => _,
                 "id" => _,
                 "processed_at" => _,
                 "to_user" => _
               }
               | _
             ] = transactions
    end

    test "when list fails due to unauthenticated user", %{conn: conn} do
      assert {:error, errors, _} = run_graphql(conn, @transactions_from_user, %{page: 1})

      assert [%{"message" => "unauthenticated"}] = errors
    end
  end

  @create_transaction """
  mutation createTransaction($input: CreateTransactionInput!) {
    createTransaction(input: $input) {
      id
      amount
      from_user
      to_user
      processed_at
    }
  }
  """

  describe "mutation: create_transaction" do
    setup do
      {:ok, sender_user} =
        build(:user_params, %{email: "sender.user@example.com"})
        |> User.changeset_create()
        |> Repo.insert()

      {:ok, receiver_user} =
        build(:user_params, %{email: "receiver.user@example.com", first_name: "Nassim", last_name: "Taleb"})
        |> User.changeset_create()
        |> Repo.insert()

      %{sender_user: sender_user, receiver_user_id: receiver_user.id}
    end

    test "when transaction successfully created", %{
      conn: conn,
      sender_user: sender_user,
      receiver_user_id: receiver_user_id
    } do
      params = %{
        input: %{
          user_id: receiver_user_id,
          amount: 2000
        }
      }

      assert {:ok, response} =
               conn
               |> authenticated(sender_user)
               |> run_graphql(@create_transaction, params)

      assert %{
               "createTransaction" => %{
                 "amount" => 2000,
                 "from_user" => _from_user,
                 "id" => _id,
                 "processed_at" => _processed_at,
                 "to_user" => _to_user
               }
             } = response
    end

    test "when transaction create fails due unauthenticated user", %{
      conn: conn,
      receiver_user_id: receiver_user_id
    } do
      params = %{
        input: %{
          user_id: receiver_user_id,
          amount: 2000
        }
      }

      assert {:error, errors, _} = run_graphql(conn, @create_transaction, params)
      assert [%{"message" => "unauthenticated"}] = errors
    end

    test "when receiver user id are invalid, should returns an error", %{
      conn: conn,
      sender_user: sender_user
    } do
      invalid_receiver_user_id = 99

      params = %{
        input: %{
          user_id: invalid_receiver_user_id,
          amount: 2000
        }
      }

      assert {:error, errors, _} =
               conn
               |> authenticated(sender_user)
               |> run_graphql(@create_transaction, params)

      assert [%{"message" => "receiver user not found"}] = errors
    end

    test "when amount param not is positive, should returns an error", %{
      conn: conn,
      sender_user: sender_user,
      receiver_user_id: receiver_user_id
    } do
      params = %{
        input: %{
          user_id: receiver_user_id,
          amount: 0
        }
      }

      assert {:error, errors, _} =
               conn
               |> authenticated(sender_user)
               |> run_graphql(@create_transaction, params)

      assert [%{"message" => "amount must be positive"}] = errors
    end
  end

  @transaction """
  query transaction($id: Int!) {
    transaction(id: $id) {
      id
      amount
      from_user
      to_user
      processed_at
    }
  }
  """

  describe "query: transaction" do
    setup do
      {:ok, sender_user} =
        build(:user_params, %{email: "sender.user@email.com"})
        |> User.changeset_create()
        |> Repo.insert()

      {:ok, receiver_user} =
        build(:user_params, %{email: "receiver.user@email.com"})
        |> User.changeset_create()
        |> Repo.insert()

      {:ok, transaction} =
        build(:transaction_params, %{from_user: sender_user.id, to_user: receiver_user.id})
        |> Transaction.changeset()
        |> Repo.insert()

      %{user: sender_user, transaction_id: transaction.id}
    end

    test "when successfully get transaction", %{
      conn: conn,
      user: user,
      transaction_id: transaction_id
    } do
      assert {:ok, response} =
               conn
               |> authenticated(user)
               |> run_graphql(@transaction, %{id: transaction_id})

      assert %{
               "transaction" => %{
                 "amount" => _,
                 "from_user" => _,
                 "id" => _,
                 "processed_at" => _,
                 "to_user" => _
               }
             } = response
    end

    test "when transaction is not found", %{conn: conn, user: user} do
      invalid_transaction_id = 99

      assert {:error, errors, _} =
               conn
               |> authenticated(user)
               |> run_graphql(@transaction, %{id: invalid_transaction_id})

      assert [%{"message" => "transaction is not found"}] = errors
    end

    test "when fails get transaction due unauthenticated user", %{
      conn: conn,
      transaction_id: transaction_id
    } do
      assert {:error, errors, _} = run_graphql(conn, @transaction, %{id: transaction_id})

      assert [%{"message" => "unauthenticated"}] = errors
    end
  end
end
