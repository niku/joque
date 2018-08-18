defmodule Joque.JobsTest do
  use ExUnit.Case, async: :ture
  doctest Joque.Jobs

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Joque.Repo)
  end

  test "insert jobs" do
    Joque.Repo.insert(%Joque.Jobs.Job{})
    Joque.Repo.insert(%Joque.Jobs.Job{})
    assert Enum.count(Joque.Repo.all(Joque.Jobs.Job)) == 2
  end
end
