defmodule MonexApiWeb.Resolvers.Transaction do
  alias MonexApi.Transaction
  alias MonexApiWeb.Helpers.TranslateErrors

  def get(%{id: transaction_id, user_id: user_id}, _context) do
    Transaction.Get.by_id(transaction_id, user_id)
  end

  def get(%{user_id: user_id, page: page}, _context) do
    Transaction.Get.by_user_id(user_id, page)
  end

  def get(_params, _context), do: {:error, "required user id or email"}

  def create(%{input: params}, _context) do
    case Transaction.Create.call(params) do
      {:error, %Ecto.Changeset{} = changeset} -> {:error, TranslateErrors.call(changeset)}
      result -> result
    end
  end
end
