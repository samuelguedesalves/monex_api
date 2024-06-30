defmodule MonexApiWeb.Schema.Operations do
  use Absinthe.Schema.Notation

  @desc "Logic user representation"
  object :transaction do
    field :id, non_null(:integer), description: "transaction id"
    field :amount, non_null(:integer), description: "transaction amount"
    field :from_user, non_null(:integer), description: "user that sender the transaction"
    field :to_user, non_null(:integer), description: "user that receiver the transaction"

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
    field :user_id, non_null(:integer)
  end
end
