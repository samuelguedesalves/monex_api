defmodule MonexApiWeb.Schema.Types.Custom.DateTime do
  use Absinthe.Schema.Notation

  scalar :datetime, name: "DateTime" do
    description("""
    The `DateTime` scalar type represents a date and time in the UTC
    timezone. The DateTime appears in a JSON response as an ISO8601 formatted
    string, including UTC timezone ("Z"). The parsed date and time string will
    be converted to UTC and any UTC offset other than 0 will be rejected.
    """)

    serialize &NaiveDateTime.to_iso8601/1
    parse &parse_datetime/1
  end

  defp parse_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} -> {:ok, datetime}
      _error -> :error
    end
  end

  defp parse_datetime(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_datetime(_) do
    :error
  end
end
