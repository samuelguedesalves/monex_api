defmodule MonexWeb.Resolvers.Operations do
  alias Monex.Operations
  alias MonexWeb.Helpers.TranslateErrors

  def get_transaction_by_id(
        %{id: transaction_id} = _params,
        %{context: %{current_user: user}} = _resolution
      ) do
    Operations.get_transaction_by_id(transaction_id, user.id)
  end

  def list_transactions_by_user_id(
        %{page: page} = _params,
        %{context: %{current_user: user}} = _resolution
      ) do
    Operations.list_transactions_by_user_id(user.id, page)
  end

  def create_transaction(
        %{input: attrs} = _params,
        %{context: %{current_user: user}} = _resolution
      ) do
    case Operations.create_transaction(user, attrs) do
      {:error, %Ecto.Changeset{} = changeset} -> {:error, TranslateErrors.call(changeset)}
      result -> result
    end
  end
end
