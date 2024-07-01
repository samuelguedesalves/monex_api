defmodule MonexApi.UsersTest do
  use MonexApi.DataCase, async: true

  # alias MonexApi.Error
  alias MonexApi.Users
  alias MonexApi.Users.User

  import MonexApi.Factory

  describe "create_user/1" do
    test "when all params are valid, should return an user struct" do
      params = build(:user_params)

      assert {:ok, %User{}} = Users.create_user(params)
    end

    test "when missing a params, should return an error" do
      params = build(:user_params) |> Map.delete(:email)

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(params)

      expected_changeset_errors = %{email: ["can't be blank"]}
      assert errors_on(changeset) == expected_changeset_errors
    end
  end

  describe "get_user_by_id/1" do
    setup do
      %User{id: user_id} =
        build(:user_params)
        |> User.changeset_create()
        |> Repo.insert!()

      %{user_id: user_id}
    end

    test "when user id are valid, should return an user struct", %{user_id: user_id} do
      assert %User{} = Users.get_user_by_id(user_id)
    end

    test "when user id are invalid, should return an error" do
      invalid_user_id = 99
      assert nil == Users.get_user_by_id(invalid_user_id)
    end
  end

  describe "get_user_by_email/1" do
    setup do
      %User{email: email} =
        build(:user_params)
        |> User.changeset_create()
        |> Repo.insert!()

      %{email: email}
    end

    test "when user email are valid, should return an user struct", %{email: email} do
      assert {:ok, %User{}} = Users.get_user_by_email(email)
    end

    test "when user id are invalid, should return error" do
      invalid_user_email = "invalid@email.com"
      assert {:error, "user not found"} == Users.get_user_by_email(invalid_user_email)
    end
  end

  describe "update_user/2" do
    setup do
      user = build(:user_params) |> User.changeset_create() |> Repo.insert!()
      %{user: user}
    end

    test "when params are valids, should update and return an user struct", %{
      user: user
    } do
      params = %{first_name: "Gabriel", last_name: "Moura", email: "gabriel.guedes@gmail.com"}

      assert {:ok, %User{}} = Users.update_user(user, params)
    end

    test "when params are invalid, should return an error", %{user: user} do
      params = %{first_name: "a", email: "a*gmail..com"}

      assert {:error, changeset} = Users.update_user(user, params)

      expected_changeset_errors = %{
        email: ["has invalid format"],
        first_name: ["should be at least 2 character(s)"]
      }

      assert errors_on(changeset) == expected_changeset_errors
    end
  end

  describe "update_user_balance/2" do
    setup do
      user = build(:user_params) |> User.changeset_create() |> Repo.insert!()
      %{user: user}
    end

    test "when balance are valids, should update and return an user", %{
      user: user
    } do
      new_balance = 99_999

      assert {:ok, %User{}} = Users.update_user_balance(user, new_balance)
    end

    test "when balance are invalid, should return error", %{user: user} do
      new_balance = -999

      assert {:error, changeset} = Users.update_user_balance(user, new_balance)

      expected_changeset_errors = %{balance: ["balance must be positive"]}

      assert errors_on(changeset) == expected_changeset_errors
    end
  end

  describe "auth_user/2" do
    setup do
      params = build(:user_params)

      %User{id: user_id} = params |> User.changeset_create() |> Repo.insert!()

      %{user_id: user_id, email: params.email, password: params.password}
    end

    test "when params are valid, should return access authorization token to user", %{
      user_id: user_id,
      email: email,
      password: password
    } do
      assert {:ok, %{user: %User{}, token: token}} = Users.auth_user(email, password)
      assert {:ok, user_id} == MonexApiWeb.AuthToken.verify(token)
    end

    test "when params are invalid, should returns authentication error", %{
      email: email
    } do
      invalid_password = "invalid password"
      assert {:error, :erro_while_authentication} == Users.auth_user(email, invalid_password)
    end
  end
end
