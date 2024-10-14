defmodule Monex.Users.Email do
  use MonexWeb, :view
  import Swoosh.Email

  alias Monex.Mailer

  @no_reply_email "noreply@monex.com"
  @theme %{
    colors: %{
      primary: "#5B24FF",
      text: "#111827",
      background: "#EEEEEE",
      foreground: "#FFFFFF"
    }
  }

  def welcome(%Monex.Users.User{} = user) do
    new()
    |> to(user.email)
    |> from(@no_reply_email)
    |> subject("Welcome to Monex")
    |> render_template(:welcome, first_name: user.first_name)
    |> Mailer.deliver()
  end

  defp render_template(email, :welcome, params) do
    styles = """
    .title {
      font-size: 30px;
      color: #{@theme.colors.primary};
      line-height: 100%;
      text-align: center;
      margin: 0;
      margin-bottom: 40px;
      padding: 0;
    }
    .message {
      font-size: 24px;
      color: #{@theme.colors.text};
      text-align: center;
      line-height: 100%;
      margin: 0;
      margin-bottom: 20px;
      padding: 0
    }
    .enjoy_app {
      font-size: 24px;
      color: #{@theme.colors.text};
      font-weight: bold;
      text-align: center;
      line-height: 100%;
      text-align: center;
    }
    """

    content = """
    <h1 class="title">Welcome to Monex!</h1>
    <p class="message">
      Dear, #{Keyword.get(params, :first_name)}.
      With Monex you can send and receive transactions.
    </p>
    <p class="enjoy_app">Enjoy Monex!</p>
    """

    template = base_layout(content, styles: styles)

    html_body(email, template)
  end

  defp base_layout(content, configs \\ []) do
    """
    <html>
      <head>
        <style>
          html {
            background-color: #{@theme.colors.background};
          }
          body {
            box-sizing: border-box;
            font-family: sans-serif;
            background-color: #{@theme.colors.foreground};
            width: 100%;
            max-width: 440px;
            margin: 12px auto;
            padding: 12px;
          }
          #{Keyword.get(configs, :styles)}
        </style>
      </head>
      <body>#{content}</body>
    </html>
    """
  end
end
