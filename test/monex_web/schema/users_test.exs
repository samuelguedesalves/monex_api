defmodule MonexWeb.Schema.UsersTest do
  use MonexWeb.ConnCase, async: false

  alias Monex.Repo
  alias Monex.Users.User

  import Monex.Factory

  @create_user """
  mutation createUser($input: CreateUserInput!) {
    createUser(input: $input) {
      user {
        id
        first_name
        last_name
        email
        balance
        inserted_at
        updated_at
      }
      token
    }
  }
  """

  describe "mutation: create_user" do
    test "when user successfully created", %{conn: conn} do
      user_params = :user_params |> build() |> Map.delete(:balance)
      payload = %{input: user_params}

      assert {:ok, response} = run_graphql(conn, @create_user, payload)

      assert %{
               "createUser" => %{
                 "user" => user_data,
                 "token" => user_token
               }
             } = response

      assert user_data["balance"] == 10_000
      assert user_data["email"] == user_params.email
      assert user_data["first_name"] == user_params.first_name
      assert user_data["last_name"] == user_params.last_name
      assert is_integer(user_data["id"])
      assert {:ok, _naive_inserted_at} = NaiveDateTime.from_iso8601(user_data["inserted_at"])
      assert {:ok, _naive_updated_at} = NaiveDateTime.from_iso8601(user_data["updated_at"])

      assert {:ok, _user_id} = MonexWeb.AuthToken.verify(user_token)
    end
  end

  @auth_user """
  mutation authUser($input: AuthUserInput!) {
    authUser(input: $input) {
      user {
        id
        first_name
        last_name
        email
        balance
        inserted_at
        updated_at
      }
      token
    }
  }
  """

  describe "mutation: auth_user" do
    setup do
      user_params = build(:user_params)

      user =
        user_params
        |> User.changeset_create()
        |> Repo.insert!()

      %{user: user}
    end

    test "when user successfully authenticated", %{conn: conn, user: user} do
      payload = %{
        input: %{
          email: user.email,
          password: user.password
        }
      }

      assert {:ok, response} = run_graphql(conn, @auth_user, payload)

      assert %{
               "authUser" => %{
                 "token" => user_token,
                 "user" => user_data
               }
             } = response

      expected_user_data = %{
        "balance" => user.balance,
        "email" => user.email,
        "first_name" => user.first_name,
        "id" => user.id,
        "inserted_at" => NaiveDateTime.to_iso8601(user.inserted_at),
        "last_name" => user.last_name,
        "updated_at" => NaiveDateTime.to_iso8601(user.updated_at)
      }

      assert expected_user_data == user_data
      assert {:ok, _user_id} = MonexWeb.AuthToken.verify(user_token)
    end

    test "when user authentication fails", %{conn: conn, user: user} do
      payload = %{
        input: %{
          email: user.email,
          password: "anything"
        }
      }

      assert {:error, errors, _} = run_graphql(conn, @auth_user, payload)

      assert [%{"message" => "error_while_authentication"}] = errors
    end
  end

  @update_user """
  mutation updateUser($input: UpdateUserInput!) {
    updateUser(input: $input) {
      id
      first_name
      last_name
      email
      balance
      inserted_at
      updated_at
    }
  }
  """

  describe "mutation: update_user" do
    setup do
      alias Monex.Repo
      alias Monex.Users.User

      user =
        build(:user_params)
        |> User.changeset_create()
        |> Repo.insert!()

      %{user: user}
    end

    test "when attributes are valid, should update user", %{conn: conn, user: user} do
      new_user_email = "different@example.com"

      payload = %{
        input: %{
          email: new_user_email
        }
      }

      assert {:ok, %{"updateUser" => user_data}} =
               conn
               |> authenticated(user)
               |> run_graphql(@update_user, payload)

      expected_user_data = %{
        "balance" => user.balance,
        "email" => new_user_email,
        "first_name" => user.first_name,
        "id" => user.id,
        "inserted_at" => NaiveDateTime.to_iso8601(user.inserted_at),
        "last_name" => user.last_name,
        "updated_at" => NaiveDateTime.to_iso8601(user.updated_at)
      }

      assert expected_user_data == user_data
    end

    test "when attributes are invalid, should return error", %{conn: conn, user: user} do
      payload = %{
        input: %{
          balance: 555_555
        }
      }

      assert {:error, errors, _} =
               conn
               |> authenticated(user)
               |> run_graphql(@update_user, payload)

      assert [
               %{
                 "message" => "Argument \"input\" has invalid value $input.\nIn field \"balance\": Unknown field."
               }
             ] = errors
    end

    test "when user is unauthenticated, should return error", %{conn: conn} do
      payload = %{
        input: %{
          first_name: "Guedes"
        }
      }

      assert {:error, errors, _} = run_graphql(conn, @update_user, payload)

      assert [%{"message" => "unauthenticated"}] = errors
    end
  end
end
