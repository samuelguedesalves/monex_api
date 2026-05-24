defmodule Monex.Operations.Worker do
  use Oban.Worker, queue: :transactions, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"transaction_id" => id}}) do
    Monex.Operations.process_transaction(id)
  end
end
