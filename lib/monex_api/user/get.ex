defmodule MonexApi.User.Get do
  alias MonexApi.{Repo, User}

  def by_id(id) do
    Repo.get(User, id)
    |> handle_get()
  end

  def by_cpf(cpf) do
    Repo.get_by(User, cpf: cpf)
    |> handle_get()
  end

  defp handle_get(%User{} = user), do: {:ok, user}

  defp handle_get(nil), do: {:error, "user is not found"}
end
