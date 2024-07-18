defmodule MonexWeb.Router do
  use MonexWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])

    plug(MonexWeb.Plugs.SetCurrentUser)
  end

  scope "/" do
    pipe_through(:api)

    forward("/api", Absinthe.Plug,
      schema: MonexWeb.Schema,
      json_codec: Jason,
      interface: :simple
    )

    forward("/graphiql", Absinthe.Plug.GraphiQL,
      schema: MonexWeb.Schema,
      interface: :playground,
      context: %{pubsub: MonexWeb.Endpoint}
    )
  end
end
