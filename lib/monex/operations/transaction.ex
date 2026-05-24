defmodule Monex.Operations.Transaction do
  use Ecto.Schema

  import Ecto.Changeset

  alias Monex.Users.User

  @params [:amount, :from_user, :to_user]
  @allowed_statuses ~w(pending processing done refuse)

  @derive {Jason.Encoder, except: [:__meta__]}

  schema "transactions" do
    field :amount, :integer
    field :from_user, :id
    field :to_user, :id
    field :status, :string

    has_one :sender_user, User, foreign_key: :id, references: :from_user
    has_one :receiver_user, User, foreign_key: :id, references: :to_user

    timestamps(inserted_at: :processed_at)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @params)
    |> validate_required(@params)
    |> check_constraint(:amount,
      name: :amount_must_be_positive,
      message: "must be positive"
    )
    |> foreign_key_constraint(:to_user)
    |> foreign_key_constraint(:from_user)
  end

  def status_changeset(transaction, status) do
    transaction
    |> cast(%{status: status}, [:status])
    |> validate_inclusion(:status, @allowed_statuses)
    |> check_constraint(:status,
      name: :status_must_be_valid,
      message: "must be a valid status"
    )
  end
end
