defmodule MonexApi.User.Create do
  alias MonexApi.{Repo, User}

  def call(params) do
    changeset = User.changeset_create(params)

    case Repo.insert(changeset) do
      {:ok, %User{} = user} -> {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end
end
