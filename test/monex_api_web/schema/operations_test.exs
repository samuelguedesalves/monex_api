defmodule MonexApiWeb.Schema.OperationsTest do
  use MonexApiWeb.ConnCase, async: false

  import MonexApi.Factory

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
      {:ok, sender_user} = MonexApi.Users.create_user(build(:user_params))

      {:ok, receiver_user} =
        :user_params
        |> build(%{"email" => "guedes.samuel@gmail.com"})
        |> MonexApi.Users.create_user()

      {:ok, _transaction01} =
        MonexApi.Operations.create_transaction(sender_user, %{
          amount: 100,
          user_id: receiver_user.id
        })

      {:ok, _transaction02} =
        MonexApi.Operations.create_transaction(receiver_user, %{
          amount: 100,
          user_id: sender_user.id
        })

      {:ok, _transaction03} =
        MonexApi.Operations.create_transaction(sender_user, %{
          amount: 100,
          user_id: receiver_user.id
        })

      %{user: sender_user}
    end

    test "when listage works", %{conn: conn, user: user} do
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

    test "when listage fails due to unauthenticated user", %{conn: conn} do
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
      {:ok, user} = MonexApi.Users.create_user(build(:user_params))

      {:ok, user01} =
        :user_params
        |> build(%{"email" => "guedes.samuel@gmail.com"})
        |> MonexApi.Users.create_user()

      %{sender_user: user, receiver_user_id: user01.id}
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
      {:ok, sender_user} = MonexApi.Users.create_user(build(:user_params))

      {:ok, receiver_user} =
        :user_params
        |> build(%{"email" => "guedes.samuel@gmail.com"})
        |> MonexApi.Users.create_user()

      {:ok, transaction} =
        MonexApi.Operations.create_transaction(sender_user, %{
          amount: 100,
          user_id: receiver_user.id
        })

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

    test "when fails get transaction due unauthenticated user", %{
      conn: conn,
      transaction_id: transaction_id
    } do
      assert {:error, errors, _} = run_graphql(conn, @transaction, %{id: transaction_id})

      assert [%{"message" => "unauthenticated"}] = errors
    end
  end
end
