defmodule Monex.Repo.Migrations.AddStatusToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :status, :string, null: false, default: "pending"
    end

    create constraint(:transactions, :status_must_be_valid,
             check: "status IN ('pending', 'processing', 'done', 'refuse')"
           )
  end
end
