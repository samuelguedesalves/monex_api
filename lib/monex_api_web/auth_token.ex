defmodule MonexApiWeb.AuthToken do
  @moduledoc """
  Creates and verifies authentication tokens.
  """

  @salt "any salt"

  def create(user) do
    Phoenix.Token.sign(MonexApiWeb.Endpoint, @salt, user.id)
  end

  def verify(token) do
    Phoenix.Token.verify(MonexApiWeb.Endpoint, @salt, token, max_age: 60 * 60 * 24)
  end
end
