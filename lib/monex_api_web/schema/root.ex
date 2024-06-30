defmodule MonexApiWeb.Schema.Root do
  use Absinthe.Schema.Notation

  alias MonexApiWeb.Resolvers.Operations, as: OperationsResolver
  alias MonexApiWeb.Resolvers.User, as: UsersResolver
  alias MonexApiWeb.Middlewares.Authentication

  # custom types
  import_types MonexApiWeb.Schema.Types.Custom.UUID4
  import_types MonexApiWeb.Schema.Types.Custom.DateTime

  # schemas
  import_types MonexApiWeb.Schema.Users
  import_types MonexApiWeb.Schema.Operations

  object :root_query do
    @desc "show current user"
    field :user, type: :user do
      arg :email, :string

      middleware Authentication

      resolve &UsersResolver.get/2
    end

    @desc "show one transaction by user"
    field :transaction, type: :transaction do
      arg :id, non_null(:integer), description: "transaction id"

      middleware Authentication

      resolve &OperationsResolver.get_transaction_by_id/2
    end

    @desc "list transactions by user"
    field :transactions_from_user, type: :transactions_pagination do
      arg :page, non_null(:integer), description: "page number"

      middleware Authentication

      resolve &OperationsResolver.list_transactions_by_user_id/2
    end
  end

  object :root_mutation do
    @desc "Auth user"
    field :auth_user, type: :user_and_token do
      arg :input, non_null(:auth_user_input)

      resolve &UsersResolver.auth/2
    end

    @desc "Create a new user"
    field :create_user, type: :user_and_token do
      arg :input, non_null(:create_user_input)

      resolve &UsersResolver.create/2
    end

    @desc "Update user"
    field :update_user, type: :user do
      arg :input, non_null(:update_user_input)

      middleware Authentication

      resolve &UsersResolver.update/2
    end

    @desc "Create a new transaction"
    field :create_transaction, type: :transaction do
      arg :input, non_null(:create_transaction_input)

      middleware Authentication

      resolve &OperationsResolver.create_transaction/2
    end
  end
end
