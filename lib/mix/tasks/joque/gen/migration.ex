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
          timestamps()
        end\
    """

    Mix.Tasks.Ecto.Gen.Migration.run(["add_jobs_table", "--change", change | args])
  end
end
