defmodule MonexWeb.Plugs.SetCurrentUser do
  @moduledoc """
  Plug to add `current_user` to the Absinthe context based on the Authorization header.
  """

  import Plug.Conn

  alias Monex.Users
  alias MonexWeb.AuthToken

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_user(conn) do
      nil -> conn
      user -> Absinthe.Plug.put_options(conn, context: %{current_user: user})
    end
  end

  defp get_user(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <- AuthToken.verify(token),
         %Users.User{} = user <- Users.get_user_by_id(user_id) do
      user
    else
      _error -> nil
    end
  end
end
