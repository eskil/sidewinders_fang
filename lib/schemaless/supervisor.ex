defmodule Schemaless.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    # http://wsmoak.net/2015/10/22/connect-four-elixir-part-1.html
    pools = for pool_config <- pool_configs do
      {name, pool_sizes, {:worker_module, worker_module}, worker_args} = pool_config
      config = [
        {:name, {:local, name}},
        {:worker_module, worker_module},
      ] ++ pool_sizes
      :poolboy.child_spec(name, config, worker_args)
    end
    for pool <- pools do
      IO.inspect pool
    end
    supervise(pools, strategy: :one_for_one)
  end

  defp pool_configs do
    # This here should be doing some yaml parsing of the db config, but instead,
    # we just do this...
    shards = Schemaless.Config.config[:shards]
    clusters = Schemaless.Config.config[:clusters]
    Enum.map(0..clusters-1, fn(cluster) ->
      {String.to_atom("Elixir.Schemaless.Pool#{cluster}"), # Name
       [ # Poolboy size args.
         {:size, 3}, # Initial pool size.
         {:max_overflow, 15} # Max number to create if empty.
       ],
       {:worker_module, Schemaless.Cluster}, # Worker module
       [ # Worker args.
         {:host, "localhost"},
         {:port, 3306},
         {:cluster, cluster},
         {:to, shards-1},
         {:step, clusters},
         {:user, "sfang"}
       ]
      }
    end)
  end
end
