defmodule MonexWeb.Schema.Users do
  use Absinthe.Schema.Notation

  @desc "Logic user representation"
  object :user do
    field :id, non_null(:integer), description: "User id"
    field :first_name, non_null(:string), description: "User first name"
    field :last_name, non_null(:string), description: "User last name"
    field :email, non_null(:string), description: "User email"
    field :balance, :integer, description: "User balance"
    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  object :user_by_email do
    import_fields :user, except: [:balance]
  end

  input_object :create_user_input do
    field :first_name, non_null(:string), description: "User first name"
    field :last_name, non_null(:string), description: "User last name"
    field :email, non_null(:string), description: "User email"
    field :password, non_null(:string), description: "User password"
  end

  input_object :update_user_input do
    field :first_name, :string, description: "User first name"
    field :last_name, :string, description: "User last name"
    field :email, :string, description: "User email"
    field :password, :string, description: "User password"
  end

  input_object :auth_user_input do
    field :email, non_null(:string), description: "User email"
    field :password, non_null(:string), description: "User password"
  end

  object :user_and_token do
    field :user, non_null(:user)
    field :token, non_null(:string)
  end
end
