defmodule Monex.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :amount, :integer, null: false
      add :from_user, references("users"), null: false
      add :to_user, references("users"), null: false

      timestamps(inserted_at: :processed_at)
    end

    create constraint(:transactions, :amount_must_be_positive, check: "amount > 0")
  end
end
