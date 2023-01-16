defmodule MonexApi.User.Create do
  alias MonexApi.{Error, Repo, User}

  def call(params) do
    changeset = User.changeset_create(params)

    case Repo.insert(changeset) do
      {:ok, %User{} = user} -> user
      {:error, %Ecto.Changeset{} = changeset} -> Error.build(:bad_request, changeset)
    end
  end
end
