defmodule MonexApi.User.Update do
  alias Ecto.Changeset
  alias MonexApi.{Error, Repo, User}

  def call(user_id, attrs) do
    with %User{} = user <- Repo.get(User, user_id),
         %Changeset{valid?: true} = changeset <- User.changeset_update(user, attrs),
         {:ok, %User{} = user} <- Repo.update(changeset) do
      user
    else
      nil -> Error.build(:not_found, "user is not found")
      %Changeset{valid?: false} = changeset -> Error.build(:bad_request, changeset)
      {:error, changeset} -> Error.build(:bad_request, changeset)
    end
  end
end
