defmodule MonexApi.User.Update do
  alias MonexApi.{Repo, User}

  def call(user_id, attrs) do
    with %User{} = user <- Repo.get(User, user_id),
         {:ok, %User{} = user} <- User.changeset_update(user, attrs) |> Repo.update() do
      {:ok, user}
    else
      nil -> {:error, "user is not found"}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
