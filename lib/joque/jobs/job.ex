defmodule Joque.Jobs.Job do
  @moduledoc """
  A representation of job in jobs context.
  """

  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "jobs" do
    field(:params, :map)
    timestamps(type: :utc_datetime)
  end
end
