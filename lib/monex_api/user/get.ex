defmodule MonexApi.User.Get do
  alias MonexApi.{Error, Repo, User}

  def by_id(id) do
    Repo.get(User, id)
    |> handle_get()
  end

  def by_email(email) do
    Repo.get_by(User, email: email)
    |> handle_get()
  end

  defp handle_get(%User{} = user), do: user

  defp handle_get(nil), do: Error.build(:not_found, "user is not found")
end
