defmodule MonexApi.Transaction.CreateTest do
  use MonexApi.DataCase, async: true

  alias MonexApi.{Transaction, User, Repo, Error}

  import MonexApi.Factory

  describe "call/1" do
    setup do
      %User{id: id_user1} =
        build(:user_params)
        |> User.changeset_create()
        |> Repo.insert!()

      %User{id: id_user2} =
        build(:user_params, %{"email" => "some2@gmail.com"})
        |> User.changeset_create()
        |> Repo.insert!()

      %{id_user1: id_user1, id_user2: id_user2}
    end

    test "when all params are valid, should return a valid transaction struct", %{
      id_user1: id_user1,
      id_user2: id_user2
    } do
      params = %{
        amount: 1000,
        from_user: id_user1,
        to_user: id_user2
      }

      result = Transaction.Create.call(params)

      assert %Transaction{from_user: from_user, to_user: to_user, amount: amount} = result
      assert from_user == id_user1
      assert to_user == id_user2
      assert amount == 1000
    end

    test "when some user id are invalid, should return a error struct with changeset", %{
      id_user1: id_user1
    } do
      params = %{
        amount: 1000,
        from_user: id_user1,
        to_user: Ecto.UUID.generate()
      }

      result = Transaction.Create.call(params)

      expected_changeset_errors = %{to_user: ["does not exist"]}

      assert %Error{status: :bad_request, result: changeset} = result
      assert errors_on(changeset) == expected_changeset_errors
    end

    test "when amount param not is positive, should return a error struct with changeset", %{
      id_user1: id_user1,
      id_user2: id_user2
    } do
      params = %{
        amount: 0,
        from_user: id_user1,
        to_user: id_user2
      }

      result = Transaction.Create.call(params)

      expected_changeset_errors = %{amount: ["amount must be positive"]}

      assert %Error{status: :bad_request, result: changeset} = result
      assert errors_on(changeset) == expected_changeset_errors
    end
  end
end
