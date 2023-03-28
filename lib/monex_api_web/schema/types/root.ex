defmodule MonexApiWeb.Schema.Types.Root do
  use Absinthe.Schema.Notation

  alias MonexApiWeb.Resolvers.Transaction, as: TransactionsResolver
  alias MonexApiWeb.Resolvers.User, as: UsersResolver

  import_types MonexApiWeb.Schema.Types.Custom.UUID4
  import_types MonexApiWeb.Schema.Types.Custom.DateTime

  import_types MonexApiWeb.Schema.Types.User
  import_types MonexApiWeb.Schema.Types.Transaction

  object :root_query do
    field :user, type: :user do
      arg :id, :uuid4
      arg :cpf, :string

      resolve &UsersResolver.get/2
    end

    @desc "show one user transaction"
    field :transaction, type: :transaction do
      arg :id, non_null(:uuid4), description: "transaction id"
      arg :user_id, non_null(:uuid4), description: "user id"

      resolve &TransactionsResolver.get/2
    end

    @desc "list transactions by user"
    field :transactions_from_user, type: :transactions_pagination do
      arg :user_id, non_null(:uuid4), description: "user id"
      arg :page, non_null(:integer), description: "page number"

      resolve &TransactionsResolver.get/2
    end
  end

  object :root_mutation do
    @desc "Create a new user"
    field :create_user, type: :user do
      arg :input, non_null(:create_user_input)

      resolve &UsersResolver.create/2
    end

    @desc "Update user"
    field :update_user, type: :user do
      arg :input, non_null(:update_user_input)

      resolve &UsersResolver.update/2
    end

    @desc "Create a new transaction"
    field :create_transaction, type: :transaction do
      arg :input, non_null(:create_transaction_input)

      resolve &TransactionsResolver.create/2
    end
  end
end
