defmodule Monex.Users.Email do
  use Phoenix.Swoosh, view: MonexWeb.EmailView

  alias Monex.Mailer
  alias Monex.Operations.Transaction
  alias Monex.Users.User

  require Logger

  @no_reply_email "noreply@monex.com"

  @doc """
  welcome/1
  send welcome email to user

  # Examples
      iex> welcome(user)
      {:ok, :email_sent}
  """
  @spec welcome(user :: User.t()) :: {:ok, :emails_sent} | {:error, :error_while_send_email_welcome}
  def welcome(%User{} = user) do
    new()
    |> to(user.email)
    |> from(@no_reply_email)
    |> subject("Welcome to Monex")
    |> render_body("welcome.html", %{name: "#{user.first_name} #{user.last_name}"})
    |> Mailer.deliver()
    |> case do
      {:ok, _term} ->
        Logger.info("welcome email was sent successfully; user id: #{user.id}")
        {:ok, :emails_sent}

      error ->
        Logger.error("error while send welcome email; user id: #{user.id}; reason: #{inspect(error)}")
        {:error, :error_while_send_email_welcome}
    end
  end

  @doc """
  operation_notification/1
  Send operation notification to both user (sender and receiver)

  # Examples
      iex> operation_notification(transaction)
      {:ok, :emails_sent}
  """
  @spec operation_notification(transaction :: Transaction.t()) ::
          {:ok, :emails_sent} | {:error, :error_while_send_email_notification}
  def operation_notification(%Transaction{} = operation) do
    transaction = Monex.Repo.preload(operation, [:sender_user, :receiver_user])

    with {:ok, _term} <- send_email_notification_to_transaction_receiver(transaction),
         {:ok, _term} <- send_email_notification_to_transaction_sender(transaction) do
      Logger.info("both transaction notification was sent successfully; transaction id: '#{transaction.id}'")
      {:ok, :emails_sent}
    else
      error ->
        Logger.error(
          "error while send transaction notifications; transaction id: '#{transaction.id}'; reason: #{inspect(error)}"
        )

        {:error, :error_while_send_email_notification}
    end
  end

  defp send_email_notification_to_transaction_receiver(
         %{sender_user: sender_user, receiver_user: receiver_user} = transaction
       ) do
    title = "Transaction Received."
    sender_name = Enum.join([sender_user.first_name, sender_user.last_name], " ")

    new()
    |> to(receiver_user.email)
    |> from(@no_reply_email)
    |> subject(title)
    |> render_body("operation_notification.html", %{
      title: title,
      sender_name: sender_name,
      transaction_id: transaction.id,
      transaction_value: transaction.amount,
      operation_nature: :received
    })
    |> Mailer.deliver()
  end

  defp send_email_notification_to_transaction_sender(
         %{sender_user: sender_user, receiver_user: receiver_user} = transaction
       ) do
    title = "Transaction Sent."
    receiver_name = Enum.join([receiver_user.first_name, receiver_user.last_name], " ")

    new()
    |> to(sender_user.email)
    |> from(@no_reply_email)
    |> subject(title)
    |> render_body("operation_notification.html", %{
      title: title,
      receiver_name: receiver_name,
      transaction_id: transaction.id,
      transaction_value: transaction.amount,
      operation_nature: :send
    })
    |> Mailer.deliver()
  end
end
