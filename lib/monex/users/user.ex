defmodule Monex.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset

  @fields [:first_name, :last_name, :email, :balance, :password]

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :balance, :integer
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps()
  end

  def changeset_create(attrs) do
    initial_user_balance = 10_000
    attrs = Map.put(attrs, :balance, initial_user_balance)

    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:first_name, min: 2, max: 12)
    |> validate_length(:last_name, min: 2, max: 12)
    |> validate_length(:password, min: 6, max: 30)
    |> validate_email()
    |> check_constraint(:balance,
      name: :balance_must_be_positive,
      message: "balance must be positive"
    )
    |> put_password_hash()
  end

  def changeset_update(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_length(:first_name, min: 2, max: 12)
    |> validate_length(:last_name, min: 2, max: 12)
    |> validate_length(:password, min: 6, max: 30)
    |> validate_email()
    |> check_constraint(:balance,
      name: :balance_must_be_positive,
      message: "balance must be positive"
    )
    |> put_password_hash()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  defp put_password_hash(%Changeset{changes: %{password: password}, valid?: true} = changeset) do
    change(changeset, Pbkdf2.add_hash(password))
  end

  defp put_password_hash(%Changeset{} = changeset), do: changeset
end
