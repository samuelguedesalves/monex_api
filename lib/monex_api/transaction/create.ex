defmodule MonexApi.Transaction.Create do
  alias MonexApi.{Repo, Transaction, User}

  def call(%{amount: _, from_user: _, to_user: _} = attrs) do
    Repo.transaction(fn ->
      with %User{} = sender_user <- Repo.get(User, attrs.from_user),
           true <- sender_user.amount >= attrs.amount,
           {:ok, %Transaction{} = transaction} <- create_transaction(attrs),
           {:ok, _user} <- update_sender_user_amount(sender_user, attrs.amount),
           {:ok, _user} <- update_receiver_user_amount(attrs.to_user, attrs.amount) do
        transaction
      else
        nil ->
          Repo.rollback("sender user not found")

        false ->
          Repo.rollback("sender user not has enough amount")

        {:error, %Ecto.Changeset{} = changeset} ->
          Repo.rollback(changeset)

        _error ->
          Repo.rollback("unexpected error is happened")
      end
    end)
  end

  def call(_attrs), do: {:error, "invalid params"}

  defp create_transaction(attrs) do
    Transaction.changeset(attrs)
    |> Repo.insert()
  end

  defp update_sender_user_amount(user, transaction_amount) do
    User.changeset_update(user, %{amount: user.amount - transaction_amount})
    |> Repo.update()
  end

  defp update_receiver_user_amount(user_id, transaction_amount) do
    user = Repo.get(User, user_id)

    User.changeset_update(user, %{amount: user.amount + transaction_amount})
    |> Repo.update()
  end
end
