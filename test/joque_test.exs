defmodule JoqueTest do
  use ExUnit.Case
  doctest Joque

  Joque.define(MyJobQueue, repo: Joque.Repo, table_name: "jobs")

  setup do
    Joque.Repo.delete_all(MyJobQueue.Job)
    :ok
  end

  test "enqueues a job" do
    Ecto.Multi.new()
    |> MyJobQueue.enqueue(%{"type" => "foo"})
    |> Joque.Repo.transaction()

    [a | []] = Joque.Repo.all(MyJobQueue.remains())

    assert a.state == "AVAILABLE"
    assert a.params == %{"type" => "foo"}
    assert Joque.Repo.all(MyJobQueue.completed()) == []
  end

  test "enqueues jobs" do
    Ecto.Multi.new()
    |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
    |> Joque.Repo.transaction()

    [a, b | []] = Joque.Repo.all(MyJobQueue.remains())

    assert a.state == "AVAILABLE"
    assert a.params == %{"type" => "foo"}
    assert b.params == %{"type" => "bar"}
    assert a.inserted_at == a.updated_at
    assert a.inserted_at == b.inserted_at
    assert a.updated_at == b.updated_at
    assert Joque.Repo.all(MyJobQueue.completed()) == []
  end

  test "perform a job" do
    Ecto.Multi.new()
    |> MyJobQueue.enqueue(%{"type" => "foo"})
    |> Joque.Repo.transaction()

    MyJobQueue.perform(fn job ->
      send(self(), job)
      {:ok, job}
    end)
    |> Joque.Repo.transaction()

    assert_received(job)
    assert(Enum.empty?(Joque.Repo.all(MyJobQueue.remains())))
    assert(Enum.count(Joque.Repo.all(MyJobQueue.completed())) == 1)
  end

  describe "performs jobs" do
    test "when all jobs completed" do
      Ecto.Multi.new()
      |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
      |> Joque.Repo.transaction()

      MyJobQueue.perform_all(fn jobs ->
        # performs jobs
        Enum.filter(
          jobs,
          fn %{params: params} ->
            send(self(), params)
          end
        )
      end)
      |> Joque.Repo.transaction()

      assert_received %{"type" => "foo"}
      assert_received %{"type" => "bar"}
      assert Joque.Repo.all(MyJobQueue.remains()) == []
      assert Enum.count(Joque.Repo.all(MyJobQueue.completed())) == 2
    end

    test "when pertial jobs completed" do
      Ecto.Multi.new()
      |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
      |> Joque.Repo.transaction()

      MyJobQueue.perform_all(fn jobs ->
        Enum.filter(
          jobs,
          fn %{params: params} ->
            if params["type"] == "bar" do
              send(self(), params)
            end
          end
        )
      end)
      |> Joque.Repo.transaction()

      assert_received %{"type" => "bar"}
      assert Joque.Repo.one(MyJobQueue.remains()).params == %{"type" => "foo"}
      assert Enum.count(Joque.Repo.all(MyJobQueue.completed())) == 1
    end

    test "when jobs didn't exist" do
      result =
        MyJobQueue.perform_all(fn jobs ->
          refute("It doesn't evaluate here.")
          jobs
        end)
        |> Joque.Repo.transaction()

      assert({:error, :joque_get_job_records, :no_jobs_found, _} = result)
    end

    test "when raised error in a performing function" do
      Ecto.Multi.new()
      |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
      |> Joque.Repo.transaction()

      result =
        MyJobQueue.perform_all(fn jobs ->
          raise("boom!")
          jobs
        end)
        |> Joque.Repo.transaction()

      assert({:error, :joque_perform_jobs, {:error_occured, _error}, _} = result)

      assert(
        Enum.count(Joque.Repo.all(MyJobQueue.remains())) == 2,
        "Getting records should be 2, we haven't any completed jobs."
      )
    end

    test "when no jobs completed" do
      Ecto.Multi.new()
      |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
      |> Joque.Repo.transaction()

      result =
        MyJobQueue.perform_all(fn _jobs ->
          []
        end)
        |> Joque.Repo.transaction()

      assert({:error, :joque_perform_jobs, :no_completed_jobs_returned, _} = result)

      assert(
        Enum.count(Joque.Repo.all(MyJobQueue.remains())) == 2,
        "Getting records should be 2, we haven't any completed jobs."
      )
    end

    test "when the return value in the performing function was invalid" do
      Ecto.Multi.new()
      |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
      |> Joque.Repo.transaction()

      result =
        MyJobQueue.perform_all(fn _jobs ->
          :some_invalid_value
        end)
        |> Joque.Repo.transaction()

      assert({:error, :joque_perform_jobs, {:unexpected_value_returned, :some_invalid_value}, _} = result)

      assert(
        Enum.count(Joque.Repo.all(MyJobQueue.remains())) == 2,
        "Getting records should be 2, we haven't any completed jobs."
      )
    end
  end

  test "concurrent performing" do
    parent = self()

    Ecto.Multi.new()
    |> MyJobQueue.enqueue_all([%{"type" => "foo"}, %{"type" => "bar"}])
    |> Joque.Repo.transaction()

    task =
      Task.async(fn ->
        MyJobQueue.perform_all(fn jobs ->
          send(parent, {self(), :processing})

          # Waiting the test has been done.
          receive do
            :done -> nil
          end

          jobs
        end)
        |> Joque.Repo.transaction()
      end)

    receive do
      {pid, :processing} ->
        # Main part of the test
        Ecto.Multi.new()
        |> MyJobQueue.enqueue(%{"type" => "baz"})
        |> Joque.Repo.transaction()

        {:ok, result} =
          MyJobQueue.perform_all(fn jobs ->
            jobs
          end)
          |> Joque.Repo.transaction()

        assert(
          Enum.count(result[:joque_get_job_records]) == 1,
          "Getting records should be 1, we inserted 3 records but 2 records have been already locked. So the rest is 1."
        )

        send(pid, :done)
    end

    Task.await(task)
  end
end
