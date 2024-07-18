defmodule MonexWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MonexWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  @endpoint MonexWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import MonexWeb.ConnCase

      alias MonexWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint MonexWeb.Endpoint
    end
  end

  setup tags do
    Monex.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Runs a GraphQL query
  """
  def run_graphql(conn, query_or_mutation, variables \\ %{}) do
    import Phoenix.ConnTest

    conn
    |> post("/api", %{"query" => query_or_mutation, "variables" => variables})
    |> json_response(200)
    |> case do
      %{"errors" => errors} = response ->
        {:error, Enum.map(errors, &Map.delete(&1, "locations")), response["data"]}

      response ->
        {:ok, response["data"]}
    end
  end

  @doc """
  Adds authentication headers to the given Plug.Conn.
  """
  def authenticated(conn, user) do
    Plug.Conn.put_req_header(
      conn,
      "authorization",
      "Bearer #{MonexWeb.AuthToken.create(user)}"
    )
  end
end
