defmodule MonexApi.User.CreateTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.{User, Error}

  import MonexApi.Factory

  describe "call/1" do
    test "when all params are valid, should return a valid user insertion" do
      params = build(:user_params)

      result = User.Create.call(params)

      assert %User{} = result
    end

    test "when missing a params, should return a error struct with changeset" do
      params = build(:user_params) |> Map.delete("email")

      result = User.Create.call(params)

      expected_changeset_errors = %{email: ["can't be blank"]}

      assert %Error{result: changeset, status: :bad_request} = result
      assert errors_on(changeset) == expected_changeset_errors
    end

    test "when amount not is positive, should return a error struct with changeset" do
      params = build(:user_params, %{"amount" => 0})

      result = User.Create.call(params)

      expected_changeset_errors = %{amount: ["amount must be positive"]}

      assert %Error{result: changeset, status: :bad_request} = result
      assert errors_on(changeset) == expected_changeset_errors
    end
  end
end
