defmodule Schemaless.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    # http://wsmoak.net/2015/10/22/connect-four-elixir-part-1.html
    for pool_config <- pool_configs do
      IO.inspect pool_config
    end
    children = for cluster <- clusters do
      worker(Schemaless.Cluster, [cluster], id: cluster)
    end
    supervise(children, strategy: :one_for_one)
  end

  defp clusters do
    # This here should be doing some yaml parsing of the db config, but instead,
    # we just do this...
    shards = Schemaless.Config.config[:shards]
    clusters = Schemaless.Config.config[:clusters]
    Enum.map(0..clusters-1, fn(cluster) ->
      {"localhost", 3306, cluster, shards-1, clusters, "sfang"}
    end)
  end

  defp pool_configs do
    # This here should be doing some yaml parsing of the db config, but instead,
    # we just do this...
    shards = Schemaless.Config.config[:shards]
    clusters = Schemaless.Config.config[:clusters]
    Enum.map(0..clusters-1, fn(cluster) ->
      {"Elixir.Schemaless.Pool#{cluster}", # Name
       [ # Poolboy size args.
         {:size, 2}, # Max pool size.
         {:max_overflow, 1} # Max number to create if empty.
       ],
       {:worker_module, Schemaless.Cluster}, # Worker module
       [ # Worker args.
         {"localhost", 3306, cluster, shards-1, clusters, "sfang"}
       ]
      }
    end)
  end
end
