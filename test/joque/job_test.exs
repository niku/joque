defmodule Joque.JobTest do
  use ExUnit.Case, async: :ture
  doctest Joque.Job

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Joque.Repo)
  end

  test "insert jobs" do
    Joque.Repo.insert(%Joque.Job{})
    Joque.Repo.insert(%Joque.Job{})
    assert Enum.count(Joque.Repo.all(Joque.Job)) == 2
  end
end
