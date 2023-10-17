defmodule MonexApi.UsersTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.Error
  alias MonexApi.Users
  alias MonexApi.Users.Schemas.User

  import MonexApi.Factory

  describe "create/1" do
    test "when all params are valid, should return a valid user insertion" do
      params = build(:user_params)

      assert {:ok, %User{} = user} = Users.create(params)

      assert params["email"] == user.email
      assert params["name"] == user.name
      assert params["password"] == user.password
      assert params["amount"] == user.amount
    end

    test "when missing a params, should return a error struct with changeset" do
      params = build(:user_params) |> Map.delete("email")

      result = Users.create(params)

      expected_changeset_errors = %{email: ["can't be blank"]}

      assert {:error, changeset} = result
      assert errors_on(changeset) == expected_changeset_errors
    end

    test "when amount not is positive, should return a error struct with changeset" do
      params = build(:user_params, %{"amount" => 0})

      result = Users.create(params)

      expected_changeset_errors = %{amount: ["amount must be positive"]}

      assert {:error, changeset} = result
      assert errors_on(changeset) == expected_changeset_errors
    end
  end

  describe "get_by_id/1" do
    setup do
      user =
        :user_params
        |> build()
        |> Users.create()

      %{user_id: user.id}
    end

    test "when user id are valid, should return a valid user struct", %{user_id: user_id} do
      result = Users.get_by_id(user_id)

      assert {:ok, %User{} = user} = result
      assert user_id == user.id
    end

    test "when user id are invalid, should return a error struct" do
      fake_user_id = Ecto.UUID.generate()

      result = Users.get_by_id(fake_user_id)

      assert {:error, :not_found} = result
    end
  end

  describe "get_by_cpf/1" do
    setup do
      user =
        :user_params
        |> build()
        |> Users.create()

      %{user_cpf: user.cpf}
    end

    test "when user cpf are valid, should return a valid user struct", %{user_cpf: user_cpf} do
      result = Users.get_by_cpf(user_cpf)

      assert {:ok, %User{} = user} = result
      assert user_cpf == user.cpf
    end

    test "when user cpf are invalid, should return a error struct" do
      fake_user_id = Ecto.UUID.generate()

      result = Users.get_by_cpf(fake_user_id)

      assert {:error, :not_found} = result
    end
  end

  describe "update/2" do
    setup do
      user =
        :user_params
        |> build()
        |> Users.create()

      %{user_id: user.id}
    end

    test "when params are valid, should update and return user struct", %{user_id: user_id} do
      attributes = %{"name" => "Monex User"}

      assert {:ok, user} = Users.update(user_id, attributes)
      assert attributes["name"] == user.name
    end

    test "when params are invalid, should return a error tuple" do
      fake_user_id = Ecto.UUID.generate()
      attributes = %{"name" => "High Order Function", "email" => "high.order@function.ex"}

      assert {:error, :not_found} = Users.update(fake_user_id, attributes)
    end
  end
end
