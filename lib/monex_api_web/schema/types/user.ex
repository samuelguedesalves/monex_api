defmodule MonexApiWeb.Schema.Types.User do
  use Absinthe.Schema.Notation

  @desc "Logic user representation"
  object :user do
    field :id, non_null(:uuid4), description: "User id"
    field :first_name, non_null(:string), description: "User first name"
    field :last_name, non_null(:string), description: "User last name"
    field :cpf, non_null(:string), description: "User CPF"
    field :amount, non_null(:integer), description: "User amount"
    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  input_object :create_user_input do
    field :first_name, non_null(:string), description: "User first name"
    field :last_name, non_null(:string), description: "User last name"
    field :cpf, non_null(:string), description: "User cpf"
    field :amount, non_null(:integer), description: "User amount"
    field :password, non_null(:string), description: "User password"
  end

  input_object :update_user_input do
    field :first_name, non_null(:string), description: "User first name"
    field :last_name, non_null(:string), description: "User last name"
    field :cpf, non_null(:string), description: "User cpf"
    field :password, non_null(:string), description: "User password"
  end
end
