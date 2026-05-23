defmodule MonexWeb.Helpers.TranslateErrors do
  import Ecto.Changeset, only: [traverse_errors: 2]

  def call(%Ecto.Changeset{} = changeset) do
    changeset
    |> traverse_errors(fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Map.to_list()
    |> Enum.map(fn {key, messages} -> "#{key} #{Enum.join(messages, ", ")}" end)
  end
end
