defmodule Joque do
  @moduledoc """
  Documentation for Joque.
  """

  def define(module, opts \\ []) do
    # credo:disable-for-previous-line Credo.Check.Refactor.CyclomaticComplexity

    defmodule Module.concat(module, Job) do
      use Ecto.Schema
      @table_name Keyword.get(opts, :table_name)
      @primary_key {:id, :binary_id, autogenerate: true}

      schema @table_name do
        field(:params, :map)
        field(:state, :string)
        timestamps(type: :utc_datetime)
      end

      def new(params) do
        %__MODULE__{params: params}
      end
    end

    defmodule module do
      import Ecto.Query

      @job Module.concat(module, Job)
      @repo Keyword.get(opts, :repo)

      def enqueue(multi, params \\ %{}) do
        multi
        |> Ecto.Multi.insert(:enqueue_job, @job.new(params))
      end

      def enqueue_all(multi, params) when is_list(params) do
        now = NaiveDateTime.utc_now()

        records =
          Enum.map(params, fn p ->
            %{params: p, inserted_at: now, updated_at: now}
          end)

        multi
        |> Ecto.Multi.insert_all(:enqueue_all_jobs, @job, records)
      end

      def remains do
        from(j in @job, where: j.state == "AVAILABLE", order_by: j.inserted_at)
      end

      def completed do
        from(j in @job, where: j.state == "COMPLETE", order_by: j.inserted_at)
      end

      def perform_all(fun) do
        Ecto.Multi.new()
        |> Ecto.Multi.run(:joque_get_job_records, &get_job_records/1)
        |> Ecto.Multi.run(:joque_perform_jobs, perform_jobs(fun))
        |> Ecto.Multi.run(:joque_update_all_job_records, &update_all_job_records/1)
      end

      @doc false
      def get_job_records(_) do
        records = @repo.all(from(j in @job, lock: "FOR UPDATE SKIP LOCKED"))

        if Enum.empty?(records) do
          {:error, :no_jobs_found}
        else
          {:ok, records}
        end
      end

      @doc false
      def perform_jobs(fun) do
        fn %{joque_get_job_records: job_records} ->
          try do
            case apply(fun, [job_records]) do
              result when is_list(result) and 0 < length(result) ->
                {:ok, result}

              result when is_list(result) ->
                {:error, :no_completed_jobs_returned}

              result ->
                {:error, {:unexpected_value_returned, result}}
            end
          rescue
            # To write assertion in the function which given perform_all as argument,
            # it needs to reraise assertion error.
            assertion_error in [ExUnit.AssertionError] ->
              reraise(assertion_error, __STACKTRACE__)

            error ->
              {:error, {:error_occured, error}}
          end
        end
      end

      @doc false
      def update_all_job_records(%{joque_perform_jobs: completed_records}) do
        completed_ids = Enum.map(completed_records, & &1.id)
        query = from(j in @job, where: j.id in ^completed_ids, update: [set: [state: "COMPLETE"]])
        {:ok, @repo.update_all(query, [])}
      end
    end
  end
end
