defmodule MonexApi.Users do
  alias MonexApi.Users.Schemas.User

  alias Ecto.Changeset
  alias MonexApi.Repo
  alias MonexApi.Error

  @doc """
  Get user by id
  """
  def get_by_id(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Get user by cpf
  """
  def get_by_cpf(cpf) do
    case Repo.get_by(User, cpf: cpf) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Create user
  """
  def create(attributes) do
    attributes
    |> User.changeset_create()
    |> Repo.insert()
  end

  @doc """
  Update user
  """
  def update(user_id, attributes) do
    with {:ok, user} <- get_by_id(user_id),
         {:ok, user} <- user |> User.changeset_update(attributes) |> Repo.update() do
      {:ok, user}
    else
      {:error, _reason} = error -> error
    end
  end
end
