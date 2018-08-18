defmodule Joque.JobsTest do
  use ExUnit.Case, async: :ture
  doctest Joque.Jobs

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Joque.Repo)
  end

  test "insert jobs" do
    Joque.Repo.insert(%Joque.Jobs.Job{params: %{"type" => "foo"}})
    Joque.Repo.insert(%Joque.Jobs.Job{params: %{"type" => "bar"}})

    import Ecto.Query
    jobs = Joque.Repo.all(from(j in Joque.Jobs.Job, order_by: j.inserted_at))
    assert Enum.count(jobs) == 2
    assert Enum.at(jobs, 0).params == %{"type" => "foo"}
  end
end
