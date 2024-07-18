defmodule Monex.Operations.Transaction do
  use Ecto.Schema

  import Ecto.Changeset

  @params [:amount, :from_user, :to_user]

  @derive {Jason.Encoder, except: [:__meta__]}

  schema "transactions" do
    field :amount, :integer
    field :from_user, :id
    field :to_user, :id

    timestamps(inserted_at: :processed_at)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @params)
    |> validate_required(@params)
    |> check_constraint(:amount,
      name: :amount_must_be_positive,
      message: "amount must be positive"
    )
    |> foreign_key_constraint(:to_user)
    |> foreign_key_constraint(:from_user)
  end
end
