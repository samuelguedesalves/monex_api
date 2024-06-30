defmodule MonexApiWeb.Router do
  use MonexApiWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])

    plug(MonexApiWeb.Plugs.SetCurrentUser)
  end

  scope "/" do
    pipe_through(:api)

    forward("/api", Absinthe.Plug,
      schema: MonexApiWeb.Schema,
      json_codec: Jason,
      interface: :simple
    )

    forward("/graphiql", Absinthe.Plug.GraphiQL,
      schema: MonexApiWeb.Schema,
      interface: :playground,
      context: %{pubsub: MonexApiWeb.Endpoint}
    )
  end
end
