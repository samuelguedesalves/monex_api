defmodule MonexWeb.Helpers.TranslateErrors do
  def call(%Ecto.Changeset{} = changeset) do
    changeset.errors
    |> Enum.map(fn {key, {message, _}} -> "#{key} #{message}" end)
  end
end
