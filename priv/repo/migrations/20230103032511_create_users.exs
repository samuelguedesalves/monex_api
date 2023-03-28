defmodule MonexApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :cpf, :string, null: false
      add :amount, :integer, null: false
      add :password_hash, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:cpf])
    create constraint(:users, :amount_must_be_positive, check: "amount >= 0")
  end
end
