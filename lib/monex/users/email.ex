defmodule Monex.Users.Email do
  import Swoosh.Email

  alias Monex.Mailer

  def welcome() do
    new()
    |> to("samuel@email.com")
    |> from("no_reply@monex.com")
    |> subject("Welcome to Monex")
    |> put_private(:phoenix_template, "welcome.html")
    |> Mailer.deliver()
  end
end
