defmodule MonexApiWeb.Middlewares.Authentication do
  @moduledoc """
  Middleware for returning an error in an Absinthe resolution when `current_user` is not available in the context.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    case resolution.context do
      %{current_user: _} -> resolution
      _ -> Absinthe.Resolution.put_result(resolution, {:error, :unauthenticated})
    end
  end
end
