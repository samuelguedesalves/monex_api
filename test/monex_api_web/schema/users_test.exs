defmodule MonexApiWeb.Schema.UsersTest do
  use MonexApiWeb.ConnCase, async: false

  import MonexApi.Factory

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
      payload = %{
        input: %{
          first_name: "Samuel",
          last_name: "Guedes",
          email: "guedes.works7@gmail.com",
          balance: 2024,
          password: "123456"
        }
      }

      assert {:ok, response} = run_graphql(conn, @create_user, payload)

      assert %{
               "createUser" => %{
                 "user" => %{
                   "balance" => 2024,
                   "email" => "guedes.works7@gmail.com",
                   "first_name" => "Samuel",
                   "id" => _id,
                   "inserted_at" => _inserted_at,
                   "last_name" => "Guedes",
                   "updated_at" => _updated_at
                 },
                 "token" => user_token
               }
             } = response

      assert {:ok, _user_id} = MonexApiWeb.AuthToken.verify(user_token)
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
      {:ok, user} = MonexApi.Users.create_user(user_params)

      %{email: user.email, password: user_params["password"]}
    end

    test "when user successfully authenticated", %{conn: conn, email: email, password: password} do
      payload = %{
        input: %{
          email: email,
          password: password
        }
      }

      assert {:ok, response} = run_graphql(conn, @auth_user, payload)

      assert %{
               "authUser" => %{
                 "token" => user_token,
                 "user" => %{
                   "balance" => 2000,
                   "email" => "samuel.guedes@gmail.com",
                   "first_name" => "Samuel",
                   "id" => _id,
                   "inserted_at" => _inserted_at,
                   "last_name" => "Guedes",
                   "updated_at" => _updated_at
                 }
               }
             } = response

      assert {:ok, _user_id} = MonexApiWeb.AuthToken.verify(user_token)
    end

    test "when user authentication fails", %{conn: conn, email: email} do
      payload = %{
        input: %{
          email: email,
          password: "anything"
        }
      }

      assert {:error, errors, _} = run_graphql(conn, @auth_user, payload)

      assert [%{"message" => "erro_while_authentication"}] = errors
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
      alias MonexApi.Repo
      alias MonexApi.Users.User

      %User{} =
        user =
        build(:user_params)
        |> User.changeset_create()
        |> Repo.insert!()

      %{user: user}
    end

    test "when attributes are valid, should update user", %{conn: conn, user: user} do
      payload = %{
        input: %{
          email: "different.example@email.com"
        }
      }

      assert {:ok, response} =
               conn
               |> authenticated(user)
               |> run_graphql(@update_user, payload)

      assert %{
               "updateUser" => %{
                 "balance" => _,
                 "email" => "different.example@email.com",
                 "first_name" => _,
                 "id" => _,
                 "inserted_at" => _,
                 "last_name" => _,
                 "updated_at" => _
               }
             } = response
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
                 "message" =>
                   "Argument \"input\" has invalid value $input.\nIn field \"balance\": Unknown field."
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
