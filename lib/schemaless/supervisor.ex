defmodule Schemaless do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    # http://wsmoak.net/2015/10/22/connect-four-elixir-part-1.html
    children = case Application.get_env(:sidewinders_fang, :poolboy) do
      :true -> for pool_config <- pool_configs do
        {name, pool_sizes, {:worker_module, worker_module}, worker_args} = pool_config
        config = [
          {:name, {:local, name}},
          {:worker_module, worker_module},
        ] ++ pool_sizes
        :poolboy.child_spec(name, config, worker_args)
      end
      _ -> for cluster <- clusters do
        worker(Schemaless.Config.driver, [cluster], id: cluster)
      end
    end

    for child <- children do
      IO.inspect child
    end

    supervise(children, strategy: :one_for_one)
  end

  defp clusters do
    # This here should be doing some yaml parsing of the db config, but instead,
    # we just do this...
    shards = Schemaless.Config.config[:shards]
    clusters = Schemaless.Config.config[:clusters]
    Enum.map(0..clusters-1, fn(cluster) ->
      [
        host: "localhost",
        port: 3306,
        cluster: cluster,
        to: shards-1,
        step: clusters,
        user: "sfang",
        password: "password",
        name: "#{Schemaless.Config.driver}#{cluster}"
      ]
    end)
  end

  defp pool_name(cluster) do
    String.to_atom("Elixir.Schemaless.Pool#{cluster}")
  end

  defp pool_configs do
    # This here should be doing some yaml parsing of the db config, but instead,
    # we just do this...
    shards = Schemaless.Config.config[:shards]
    clusters = Schemaless.Config.config[:clusters]
    Enum.map(0..clusters-1, fn(cluster) ->
      {pool_name(cluster), # Name
       [
         # Poolboy size args.
         {:size, 3}, # Initial pool size.
         {:max_overflow, 3} # Max number to create if empty.
       ],
       {:worker_module, Schemaless.Config.driver}, # Worker module
       [
         # Worker args.
         {:host, "localhost"},
         {:password, "password"},
         {:port, 3306},
         {:cluster, cluster},
         {:to, shards-1},
         {:step, clusters},
         {:user, "sfang"},
         {:name, nil}
       ]
      }
    end)
  end

  def get_cell(datastore, uuid) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          pool_name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:get_cell, shard, datastore, uuid})
          end
        )
      _ ->
        Schemaless.Config.driver.get_cell(cluster, shard, datastore, uuid)
    end
  end

  def get_cell(datastore, uuid, column) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          pool_name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:get_cell, shard, datastore, uuid, column})
          end
        )
      _ ->
        Schemaless.Config.driver.get_cell(cluster, shard, datastore, uuid, column)
    end
  end

  def get_cell(datastore, uuid, column, ref_key) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          pool_name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:get_cell, shard, datastore, uuid, column, ref_key})
          end
        )
      _ ->
        Schemaless.Config.driver.get_cell(cluster, shard, datastore, uuid, column, ref_key)
    end
  end

  def put_cell(datastore, uuid, columns) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          pool_name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:put_cell, shard, datastore, uuid, columns})
      end
        )
      _ ->
        Schemaless.Config.driver.put_cell(cluster, shard, datastore, uuid, columns)
    end
  end
end
