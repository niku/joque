defmodule Joque.Job do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "jobs" do
    timestamps(type: :utc_datetime)
  end
end
