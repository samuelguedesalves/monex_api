defmodule MonexApi.Transaction.Create do
  alias MonexApi.{Error, Repo, Transaction}

  def call(attrs) do
    changeset = Transaction.changeset(attrs)

    case Repo.insert(changeset) do
      {:ok, %Transaction{} = transaction} -> transaction
      {:error, %Ecto.Changeset{} = changeset} -> Error.build(:bad_request, changeset)
    end
  end
end
