defmodule MonexApi.Operations do
  @moduledoc """
  Module to operate entity Operations
  """

  import Ecto.Query

  alias MonexApi.Operations.Transaction
  alias MonexApi.Repo
  alias MonexApi.Users
  alias MonexApi.Users.User

  require Logger

  @doc """
  get_transaction_by_id(transaction_id, user_id)

  # Example of the usage:

      iex> transaction_id = 1
      iex> user_id = 1
      iex> get_transaction_by_id(transaction_id, user_id)
      {:ok, %Transaction{}} | {:error, reason}
  """
  @spec get_transaction_by_id(transaction_id :: Integer.t(), user_id :: Integer.t()) ::
          {:ok, Transaction.t()} | {:error, reason :: String.t()}
  def get_transaction_by_id(transaction_id, user_id) do
    Logger.info("transaction will be read. transaction id: '#{transaction_id}', and user id: '#{user_id}'")

    Transaction
    |> from()
    |> where([t], t.id == ^transaction_id and (t.from_user == ^user_id or t.to_user == ^user_id))
    |> Repo.one()
    |> case do
      result when is_nil(result) ->
        Logger.error("transaction with id '#{transaction_id}', from user with id '#{user_id}'. was not found")

        {:error, "transaction is not found"}

      %Transaction{} = transaction ->
        Logger.info("transaction with id '#{transaction_id}', from user with id '#{user_id}'. was founded")

        {:ok, transaction}
    end
  end

  def list_transactions_by_user_id(user_id, page) when page <= 0,
    do: list_transactions_by_user_id(user_id, 1)

  @doc """
  list_transactions_by_user_id(user_id, page)

  # Example of the usage:

      iex> user_id = 1
      iex> page = 1
      iex> list_transactions_by_user_id(user_id, page)
      {:ok, result}
  """
  @spec list_transactions_by_user_id(user_id :: Integer.t(), page :: Integer.t()) ::
          {:ok,
           %{
             page: Integer.t(),
             transactions: list(Transaction.t()),
             quantity: Integer.t(),
             next_page: Integer.t(),
             previous_page: Integer.t()
           }}
  def list_transactions_by_user_id(user_id, page) do
    page_size = 10
    skip = page * page_size - page_size

    transactions =
      Transaction
      |> from()
      |> where([t], t.from_user == ^user_id or t.to_user == ^user_id)
      |> order_by([t], desc: t.processed_at)
      |> offset(^skip)
      |> limit(^page_size)
      |> Repo.all()

    previous_page = if page > 1, do: page - 1, else: 1

    result = %{
      page: page,
      transactions: transactions,
      quantity: length(transactions),
      next_page: page + 1,
      previous_page: previous_page
    }

    {:ok, result}
  end

  @doc """
  create_transaction(sender_user, params)

  # Example of usage:

      iex> sender_user = %User{}
      iex> params = %{amount: 500, user_id: 99}
      iex> create_transaction(sender_user, params)
      {:ok, %Transaction{}} | {:error, %Ecto.Changeset{}}
  """
  @spec create_transaction(
          sender_user :: User.t(),
          params :: %{amount: Integer.t(), user_id: Integer.t()}
        ) :: {:ok, Transaction.t()} | {:error, reason :: Ecto.Changeset.t() | String.t()}
  def create_transaction(%User{} = sender_user, %{amount: amount, user_id: user_id}) do
    Repo.transaction(fn ->
      with :greater_or_equal_than <- verify_user_balance(sender_user, amount),
           %User{} = receiver_user <- Users.get_user_by_id(user_id),
           {:ok, %Transaction{} = transaction} <-
             insert_transaction(%{
               amount: amount,
               from_user: sender_user.id,
               to_user: receiver_user.id
             }),
           {:ok, %User{}} <- update_sender_user_balance(sender_user, amount),
           {:ok, %User{}} <- update_receiver_user_balance(receiver_user, amount) do
        Logger.info("[Operation] transaction successfully created")
        transaction
      else
        nil ->
          Logger.error("[Operation] error while creating transaction due user not found")
          Repo.rollback("sender user not found")

        :less_than ->
          Logger.error("[Operation] error while creating transaction due user balance is less than transaction")

          Repo.rollback("sender user not has enough amount")

        {:error, %Ecto.Changeset{} = changeset} ->
          Logger.error("[Operation] error while creating transaction due #{inspect(changeset)}")
          Repo.rollback(changeset)

        error ->
          Logger.error("[Operation] error while creating transaction due #{inspect(error)}")
          Repo.rollback("unexpected error is happened")
      end
    end)
  end

  defp verify_user_balance(%User{balance: balance}, amount) do
    if balance >= amount,
      do: :greater_or_equal_than,
      else: :less_than
  end

  defp insert_transaction(attrs) do
    attrs
    |> Transaction.changeset()
    |> Repo.insert()
  end

  defp update_sender_user_balance(user, transaction_amount) do
    new_user_balance = user.balance - transaction_amount
    Users.update_user_balance(user, new_user_balance)
  end

  defp update_receiver_user_balance(user, transaction_amount) do
    new_user_balance = user.balance + transaction_amount
    Users.update_user_balance(user, new_user_balance)
  end
end
