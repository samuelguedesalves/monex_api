defmodule MonexApi.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset

  @fields [:name, :email, :password, :amount]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :name, :string
    field :password_hash, :string
    field :amount, :integer
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset_create(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, min: 6, max: 30)
    |> validate_length(:name, min: 2, max: 30)
    |> validate_length(:password, min: 6, max: 30)
    |> unique_constraint(:email)
    |> check_constraint(:amount,
      name: :amount_must_be_positive,
      message: "amount must be positive"
    )
    |> put_password_hash()
  end

  def changeset_update(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, min: 6, max: 30)
    |> validate_length(:name, min: 2, max: 30)
    |> validate_length(:password, min: 6, max: 30)
    |> unique_constraint(:email)
    |> check_constraint(:amount,
      name: :amount_must_be_positive,
      message: "amount must be positive"
    )
    |> put_password_hash()
  end

  defp put_password_hash(%Changeset{changes: %{password: password}, valid?: true} = changeset) do
    change(changeset, Pbkdf2.add_hash(password))
  end

  defp put_password_hash(%Changeset{} = changeset), do: changeset
end
