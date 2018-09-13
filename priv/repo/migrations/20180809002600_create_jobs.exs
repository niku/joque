defmodule Joque.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table("jobs", primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:state, :string, null: false, default: "AVAILABLE", comment: "State of the job")
      add(:params, :map, null: false, default: %{}, comment: "Serialized job parameters")
      timestamps(type: :utc_datetime)
    end
  end
end
