defmodule MonexWeb.AuthToken do
  @moduledoc """
  Creates and verifies authentication tokens.
  """

  @salt "any salt"

  def create(user) do
    Phoenix.Token.sign(MonexWeb.Endpoint, @salt, user.id)
  end

  def verify(token) do
    Phoenix.Token.verify(MonexWeb.Endpoint, @salt, token, max_age: 60 * 60 * 24)
  end
end
