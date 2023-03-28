defmodule MonexApiWeb.Helpers.TranslateErrors do
  # import Ecto.Changeset, only: [traverse_errors: 2]

  # def call(%Ecto.Changeset{} = changeset) do
  #   traverse_errors(changeset, fn {msg, opts} ->
  #     Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
  #       opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
  #     end)
  #   end)
  # end

  def call(%Ecto.Changeset{} = changeset) do
    changeset.errors
    |> Enum.map(fn {key, {message, _}} -> "#{key} #{message}" end)
  end
end
