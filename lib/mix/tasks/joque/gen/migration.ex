defmodule Mix.Tasks.Joque.Gen.Migration do
  use Mix.Task

  @shortdoc "Generates a new job migration for the repo"
  @moduledoc @shortdoc

  @doc false
  def run(args) do
    change = """
        create table("jobs") do
          add(:state, :string, null: false, default: "AVAILABLE", comment: "State of the job")
          add(:params, :map, null: false, default: %{}, comment: "Serialized job parameters")
          add(:queued_at, :utc_datetime, null: false, default: fragment("now()"), comment: "Queued datetime(UTC)")
          timestamps(type: :utc_datetime)
        end

        create index("jobs", [:queued_at])\
    """

    Mix.Tasks.Ecto.Gen.Migration.run(["add_jobs_table", "--change", change | args])
  end
end
