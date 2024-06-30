defmodule MonexApi.CustomLoggerFormatter do
  @log_levels [:error, :warn, :info, :debug]

  def format(level, message, timestamp, metadata) when level in @log_levels do
    # formate module name
    module = metadata[:module]
    formatted_module = Atom.to_string(module) |> String.replace_prefix("Elixir.", "")

    # format timestamp
    {{year, month, day}, {hour, minute, second, _microsecond}} = timestamp
    naive_datetime = NaiveDateTime.new!(year, month, day, hour, minute, second)
    formatted_timestamp = NaiveDateTime.to_string(naive_datetime)

    # formate, mount log message, and write
    "[#{level}] [#{formatted_module}] [#{formatted_timestamp}] #{message}\n"
    |> IO.iodata_to_binary()
  end
end
