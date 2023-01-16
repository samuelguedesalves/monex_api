defmodule MonexApi.User.GetTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.{User, Error}

  import MonexApi.Factory

  describe "by_id/1" do
    setup do
      %User{id: user_id} =
        build(:user_params)
        |> User.Create.call()

      %{user_id: user_id}
    end

    test "when user id are valid, should return a valid user struct", %{user_id: user_id} do
      result = User.Get.by_id(user_id)

      assert %User{} = result
    end

    test "when user id are invalid, should return a error struct" do
      result = User.Get.by_id(Ecto.UUID.generate())

      assert %Error{result: "user is not found", status: :not_found} = result
    end
  end

  describe "by_email/1" do
    setup do
      %User{email: email} =
        build(:user_params)
        |> User.Create.call()

      %{email: email}
    end

    test "when user email are valid, should return a valid user struct", %{email: email} do
      result = User.Get.by_email(email)

      assert %User{} = result
    end

    test "when user id are invalid, should return a error struct" do
      result = User.Get.by_email("")

      assert %Error{result: "user is not found", status: :not_found} = result
    end
  end
end
