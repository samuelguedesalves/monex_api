defmodule MonexApi.Transaction.Get do
  import Ecto.Query

  alias MonexApi.{Error, Repo, Transaction}

  def by_id(transaction_id, user_id) do
    query =
      from t in Transaction,
        where: t.id == ^transaction_id and (t.from_user == ^user_id or t.to_user == ^user_id)

    case Repo.one(query) do
      nil -> Error.build(:bad_request, "transaction is not found")
      %Transaction{} = transaction -> transaction
    end
  end

  def by_user_id(user_id, page) when page <= 0, do: by_user_id(user_id, 1)

  def by_user_id(user_id, page) do
    page_size = 10
    skipe = page * page_size - page_size

    query =
      from t in Transaction,
        where: t.from_user == ^user_id or t.to_user == ^user_id,
        order_by: [desc: t.processed_at],
        offset: ^skipe,
        limit: ^page_size

    transactions = Repo.all(query)

    %{
      page: page,
      transactions: transactions,
      quantity: length(transactions),
      next_page: page + 1,
      previous_page: (fn -> if page > 1, do: page - 1, else: 1 end).()
    }
  end
end
