defmodule Monex.Operations do
  @moduledoc """
  Module to operate entity Operations
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Monex.Operations.Transaction
  alias Monex.Repo
  alias Monex.Users
  alias Monex.Users.Email
  alias Monex.Users.User

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
  create_transaction/2

  # Examples:
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
    Multi.new()
    |> Multi.run(:verify_user_balance, fn _repo, _changes ->
      verify_user_balance(sender_user, amount)
    end)
    |> Multi.run(:receiver_user, fn _repo, _changes ->
      get_receiver_user(user_id)
    end)
    |> Multi.run(:insert_transaction, fn _repo, %{receiver_user: receiver_user} ->
      insert_transaction(%{
        amount: amount,
        from_user: sender_user.id,
        to_user: receiver_user.id
      })
    end)
    |> Multi.run(:update_sender_user_balance, fn _repo, _changes ->
      update_sender_user_balance(sender_user, amount)
    end)
    |> Multi.run(:update_receiver_user_balance, fn _repo, %{receiver_user: receiver_user} ->
      update_receiver_user_balance(receiver_user, amount)
    end)
    |> Multi.run(:send_transaction_notification, fn _repo, %{insert_transaction: transaction} ->
      send_transaction_notification(transaction)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{insert_transaction: transaction}} ->
        Logger.info("[Operation] transaction successfully created")
        {:ok, transaction}

      {:error, :receiver_user, :receiver_user_not_found, _changes} ->
        Logger.error("[Operation] error while creating transaction. receiver user not found")
        {:error, "receiver user not found"}

      {:error, :verify_user_balance, :less_than, _changes} ->
        Logger.error("[Operation] error while creating transaction. user not have balance enough to transaction")
        {:error, "sender user not have balance enough for transaction"}

      {:error, :insert_transaction, %Ecto.Changeset{} = changeset, _changes} ->
        Logger.error("[Operation] error while insert transaction due: #{inspect(changeset)}")
        {:error, changeset}

      {:error, :update_sender_user_balance, %Ecto.Changeset{} = changeset, _changes} ->
        Logger.error("[Operation] error while update sender user balance due: #{inspect(changeset)}")
        {:error, changeset}

      {:error, :update_receiver_user_balance, %Ecto.Changeset{} = changeset, _changes} ->
        Logger.error("[Operation] error while update receiver user balance due: #{inspect(changeset)}")
        {:error, changeset}

      error ->
        Logger.error("[Operation] unexpected error happened while creation of transaction: #{inspect(error)}")
        {:error, "unexpected error while transaction creation"}
    end
  end

  @spec verify_user_balance(user :: User.t(), amount :: Integer.t()) ::
          {:error, :less_than} | {:ok, :greater_or_equal_than}
  defp verify_user_balance(%User{balance: balance} = _user, amount) do
    if balance >= amount,
      do: {:ok, :greater_or_equal_than},
      else: {:error, :less_than}
  end

  @spec get_receiver_user(receiver_user_id :: Integer.t()) :: {:ok, User.t()} | {:error, :receiver_user_not_found}
  defp get_receiver_user(receiver_user_id) do
    case Users.get_user_by_id(receiver_user_id) do
      nil -> {:error, :receiver_user_not_found}
      user -> {:ok, user}
    end
  end

  @spec insert_transaction(attrs :: Map.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  defp insert_transaction(attrs) do
    attrs
    |> Transaction.changeset()
    |> Repo.insert()
  end

  @spec update_sender_user_balance(user :: User.t(), transaction_amount :: Integer.t()) ::
          {:ok, Monex.Users.User.t()} | {:error, Ecto.Changeset.t()}
  defp update_sender_user_balance(user, transaction_amount) do
    new_user_balance = user.balance - transaction_amount
    Users.update_user_balance(user, new_user_balance)
  end

  @spec update_receiver_user_balance(user :: User.t(), transaction_amount :: Integer.t()) ::
          {:ok, Monex.Users.User.t()} | {:error, Ecto.Changeset.t()}
  defp update_receiver_user_balance(user, transaction_amount) do
    new_user_balance = user.balance + transaction_amount
    Users.update_user_balance(user, new_user_balance)
  end

  defp send_transaction_notification(transaction) do
    Email.operation_notification(transaction)
    {:ok, :notification_queued}
  end
end
