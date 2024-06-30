defmodule MonexApiWeb.Resolvers.User do
  alias MonexApi.Users
  alias MonexApiWeb.Helpers.TranslateErrors

  def get(%{email: user_email}, _context) do
    case Users.get_user_by_email(user_email) do
      {:ok, user} ->
        {:ok, user |> Map.from_struct() |> Map.delete(:balance)}

      error ->
        error
    end
  end

  def get(_params, %{context: %{current_user: user}} = _context) do
    {:ok, user}
  end

  def get(_params, _context), do: {:error, "required user id or email"}

  def create(%{input: params}, _context) do
    case Users.create_user(params) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, TranslateErrors.call(changeset)}

      {:ok, user} ->
        {:ok, %{user: user, token: MonexApiWeb.AuthToken.create(user)}}
    end
  end

  def update(%{input: attrs}, %{context: %{current_user: user}} = _resolution) do
    case Users.update_user(user, attrs) do
      {:error, %Ecto.Changeset{} = changeset} -> {:error, TranslateErrors.call(changeset)}
      result -> result
    end
  end

  def auth(%{input: %{email: email, password: password}}, _context) do
    Users.auth_user(email, password)
  end
end
