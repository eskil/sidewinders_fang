defmodule Schemaless.Store do
  use GenServer

  defp name(cluster) do
    String.to_atom("Elixir.Schemaless.Pool#{cluster}")
  end

  def get_cell(datastore, uuid) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:get_cell, shard, datastore, uuid})
          end
        )
      _ ->
        IO.puts "pool less get_cell"
        Schemaless.Config.driver.get_cell(cluster, shard, datastore, uuid)
    end
  end

  def get_cell(datastore, uuid, column) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:get_cell, shard, datastore, uuid, column})
          end
        )
      _ ->
        IO.puts "pool less get_cell"
        Schemaless.Config.driver.get_cell(cluster, shard, datastore, uuid, column)
    end
  end

  def get_cell(datastore, uuid, column, ref_key) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:get_cell, shard, datastore, uuid, column, ref_key})
          end
        )
      _ ->
        IO.puts "pool less get_cell"
        Schemaless.Config.driver.get_cell(cluster, shard, datastore, uuid, column, ref_key)
    end
  end

  def put_cell(datastore, uuid, columns) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        :poolboy.transaction(
          name(cluster),
          fn(pid) ->
            :gen_server.call(pid, {:put_cell, shard, datastore, uuid, columns})
      end
        )
      _ ->
        IO.puts "pool less put_cell"
        Schemaless.Config.driver.put_cell(cluster, shard, datastore, uuid, columns)
    end
  end
end
