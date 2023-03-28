defmodule MonexApi.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset

  @fields [:first_name, :last_name, :cpf, :amount, :password]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :cpf, :string
    field :amount, :integer
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset_create(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:first_name, min: 2, max: 12)
    |> validate_length(:last_name, min: 2, max: 12)
    |> validate_length(:password, min: 6, max: 30)
    |> validate_cpf()
    |> unique_constraint(:cpf)
    |> check_constraint(:amount,
      name: :amount_must_be_positive,
      message: "amount must be positive"
    )
    |> put_password_hash()
  end

  def changeset_update(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_length(:first_name, min: 2, max: 12)
    |> validate_length(:last_name, min: 2, max: 12)
    |> validate_length(:password, min: 6, max: 30)
    |> validate_cpf()
    |> unique_constraint(:cpf)
    |> check_constraint(:amount,
      name: :amount_must_be_positive,
      message: "amount must be positive"
    )
    |> put_password_hash()
  end

  defp validate_cpf(%Changeset{changes: %{cpf: cpf}, valid?: true} = changeset) do
    if Brcpfcnpj.cpf_valid?(cpf),
      do: change(changeset, %{cpf: Brcpfcnpj.cpf_format(cpf)}),
      else: add_error(changeset, :cpf, "field must be valid")
  end

  defp validate_cpf(changeset), do: changeset

  defp put_password_hash(%Changeset{changes: %{password: password}, valid?: true} = changeset) do
    change(changeset, Pbkdf2.add_hash(password))
  end

  defp put_password_hash(%Changeset{} = changeset), do: changeset
end
