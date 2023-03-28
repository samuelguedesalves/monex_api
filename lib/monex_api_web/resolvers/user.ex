defmodule MonexApiWeb.Resolvers.User do
  alias MonexApi.User
  alias MonexApiWeb.Helpers.TranslateErrors

  def get(%{id: user_id}, _context), do: User.Get.by_id(user_id)

  def get(%{cpf: user_cpf}, _context), do: User.Get.by_cpf(user_cpf)

  def get(_params, _context), do: {:error, "required user id or cpf"}

  def create(%{input: params}, _context) do
    case User.Create.call(params) do
      {:error, %Ecto.Changeset{} = changeset} -> {:error, TranslateErrors.call(changeset)}
      result -> result
    end
  end

  def update(%{input: %{user_id: user_id, attrs: attrs}}, _context) do
    case User.Update.call(user_id, attrs) do
      {:error, %Ecto.Changeset{} = changeset} -> {:error, TranslateErrors.call(changeset)}
      result -> result
    end
  end
end
