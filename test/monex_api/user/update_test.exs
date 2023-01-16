defmodule MonexApi.User.UpdateTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.{User, Error}

  import MonexApi.Factory

  describe "call/2" do
    setup do
      %User{id: user_id} = build(:user_params) |> User.changeset_create() |> Repo.insert!()

      %{user_id: user_id}
    end

    test "when params are valids, should update and return the valid transaction", %{
      user_id: user_id
    } do
      params = %{name: "some another", email: "some_another@gmail.com"}

      result = User.Update.call(user_id, params)

      assert %User{} = result
    end

    test "when user id are valids, should return error" do
      params = %{name: "some another", email: "some_another@gmail.com"}

      result = User.Update.call(Ecto.UUID.generate(), params)

      expected_result = %Error{result: "user is not found", status: :not_found}

      assert expected_result == result
    end
  end
end
