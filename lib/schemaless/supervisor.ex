defmodule Schemaless.Supervisor do
  use Supervisor
  use Bitwise

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    # http://wsmoak.net/2015/10/22/connect-four-elixir-part-1.html
    children = for cluster <- clusters do
      worker(Schemaless.Cluster, [cluster], id: cluster)
    end
    access = worker(Schemaless.Store, [config])
    all_children = children ++ [access]
    supervise(all_children, strategy: :one_for_one)
  end

  def clusters do
    # This here should be doing some yaml parsing of the db config, but instead,
    # we just do this...
    shards = config[:shards]
    clusters = config[:clusters]
    Enum.map(0..clusters-1, fn(cluster) ->
      {"localhost", 3306, cluster, shards-1, clusters, "sfang"}
    end)
  end

  def config do
    %{shards: 4096, clusters: 16}
  end
end
