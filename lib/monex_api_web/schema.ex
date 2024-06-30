defmodule MonexApiWeb.Schema do
  use Absinthe.Schema

  import_types MonexApiWeb.Schema.Root

  query do
    import_fields :root_query
  end

  mutation do
    import_fields :root_mutation
  end
end
