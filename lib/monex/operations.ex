defmodule Monex.Operations do
  @moduledoc """
  Module to operate entity Operations
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Monex.Operations.Transaction
  alias Monex.Operations.Worker
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

  Inserts a pending transaction and enqueues a background job to settle it.
  Balance verification and debiting happen in the worker to prevent race conditions
  between concurrent requests.

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
    |> Repo.transaction()
    |> case do
      {:ok, %{insert_transaction: transaction}} ->
        Logger.info("[Operation] pending transaction created, enqueueing settlement job")
        {:ok, _job} = Oban.insert(Worker.new(%{transaction_id: transaction.id}))
        {:ok, Repo.reload!(transaction)}

      {:error, :receiver_user, :receiver_user_not_found, _changes} ->
        Logger.error("[Operation] error while creating transaction. receiver user not found")
        {:error, "receiver user not found"}

      {:error, :insert_transaction, %Ecto.Changeset{} = changeset, _changes} ->
        Logger.error("[Operation] error while insert transaction due: #{inspect(changeset)}")
        {:error, changeset}

      error ->
        Logger.error("[Operation] unexpected error happened while creation of transaction: #{inspect(error)}")
        {:error, "unexpected error while transaction creation"}
    end
  end

  @doc """
  process_transaction/1

  Settles a pending transaction: verifies sender balance, debits sender, credits receiver,
  and sends email notifications. Called by Monex.Operations.Worker.

  Returns :ok for both successful settlement and business-rule refusals (insufficient balance).
  Returns {:error, reason} only for transient infrastructure failures so Oban retries.

  # Examples:
      iex> process_transaction(1)
      :ok | {:error, reason}
  """
  @spec process_transaction(transaction_id :: Integer.t()) :: :ok | {:error, reason :: any()}
  def process_transaction(transaction_id) do
    transaction = Repo.get!(Transaction, transaction_id)

    if transaction.status != "pending" do
      Logger.info("[Operation] transaction #{transaction_id} is not pending (#{transaction.status}), skipping")
      :ok
    else
      do_process_transaction(transaction)
    end
  end

  defp do_process_transaction(transaction) do
    sender_user = Users.get_user_by_id(transaction.from_user)

    Multi.new()
    |> Multi.run(:verify_balance, fn _repo, _changes ->
      verify_user_balance(sender_user, transaction.amount)
    end)
    |> Multi.run(:debit_sender, fn _repo, _changes ->
      Users.update_user_balance(sender_user, sender_user.balance - transaction.amount)
    end)
    |> Multi.run(:credit_receiver, fn _repo, _changes ->
      receiver_user = Users.get_user_by_id(transaction.to_user)
      Users.update_user_balance(receiver_user, receiver_user.balance + transaction.amount)
    end)
    |> Multi.run(:settled_transaction, fn _repo, _changes ->
      Transaction.status_changeset(transaction, "done") |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{settled_transaction: settled}} ->
        Logger.info("[Operation] transaction #{transaction.id} settled successfully")
        send_notification_safely(settled)
        :ok

      {:error, :verify_balance, :less_than, _changes} ->
        Logger.error("[Operation] transaction #{transaction.id} refused: insufficient balance")
        set_transaction_status(transaction, "refuse")
        :ok

      {:error, _step, reason, _changes} ->
        Logger.error("[Operation] transaction #{transaction.id} failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp send_notification_safely(transaction) do
    case Email.operation_notification(transaction) do
      {:ok, _} ->
        :ok

      error ->
        Logger.error("[Operation] failed to send notification for transaction #{transaction.id}: #{inspect(error)}")
        :ok
    end
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

  @spec verify_user_balance(user :: User.t(), amount :: Integer.t()) ::
          {:error, :less_than} | {:ok, :greater_or_equal_than}
  defp verify_user_balance(%User{balance: balance} = _user, amount) do
    if balance >= amount,
      do: {:ok, :greater_or_equal_than},
      else: {:error, :less_than}
  end

  defp set_transaction_status(transaction, status) do
    transaction
    |> Transaction.status_changeset(status)
    |> Repo.update()
  end
end
