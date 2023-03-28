defmodule MonexApiWeb.Schema.Types.Transaction do
  use Absinthe.Schema.Notation

  # import_types MonexApiWeb.Schema.Types.Custom.UUID4
  # import_types MonexApiWeb.Schema.Types.Custom.DateTime

  @desc "Logic user representation"
  object :transaction do
    field :id, non_null(:uuid4), description: "transaction id"
    field :amount, non_null(:integer), description: "transaction amount"
    field :from_user, non_null(:uuid4), description: "user that sender the transaction"
    field :to_user, non_null(:uuid4), description: "user that receiver the transaction"

    field :processed_at, non_null(:datetime),
      description: "datetime when the transaction is processed"
  end

  object :transactions_pagination do
    field :page, :integer
    field :transactions, list_of(:transaction)
    field :quantity, :integer
    field :next_page, :integer
    field :previous_page, :integer
  end

  input_object :create_transaction_input do
    field :amount, non_null(:integer)
    field :from_user, non_null(:uuid4)
    field :to_user, non_null(:uuid4)
  end
end
