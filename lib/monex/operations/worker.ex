defmodule Monex.Operations.Worker do
  use Oban.Worker, queue: :transactions

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    IO.inspect(args, label: :oban_job_worker_args)
    :ok
  end
end
