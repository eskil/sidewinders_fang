defmodule Schemaless.Store do
  use GenServer
  use Bitwise

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    {:ok, config}
  end

  def get_cell(datastore, uuid) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid})
  end

  def get_cell(datastore, uuid, column) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid, column})
  end

  def get_cell(datastore, uuid, column, ref_key) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid, column, ref_key})
  end

  def put_cell(datastore, uuid, columns) do
    GenServer.call(__MODULE__, {:put_cell, datastore, uuid, columns})
  end

  def handle_call({:get_cell, datastore, uuid}, _from, state) do
    shard = shard_number(uuid, state[:clusters])
    cluster = cluster_number(shard, state[:clusters])
    {:reply, Schemaless.Cluster.get_cell(cluster, shard, datastore, uuid), state}
  end

  def handle_call({:get_cell, datastore, uuid, column}, _from, state) do
    shard = shard_number(uuid, state[:clusters])
    cluster = cluster_number(shard, state[:clusters])
    {:reply, Schemaless.Cluster.get_cell(cluster, shard, datastore, uuid, column), state}
  end

  def handle_call({:get_cell, datastore, uuid, column, ref_key}, _from, state) do
    shard = shard_number(uuid, state[:clusters])
    cluster = cluster_number(shard, state[:clusters])
    {:reply, Schemaless.Cluster.get_cell(cluster, shard, datastore, uuid, column, ref_key), state}
  end

  def handle_call({:put_cell, datastore, uuid, columns}, _from, state) do
    shard = shard_number(uuid, state[:clusters])
    cluster = cluster_number(shard, state[:clusters])
    {:reply, Schemaless.Cluster.put_cell(cluster, shard, datastore, uuid, columns), state}
  end

  defp shard_number(uuid, clusters) do
    binlist = UUID.info!(uuid)[:binary]
    |> :binary.bin_to_list
    rem((Enum.at(binlist, 14) <<< 8) + Enum.at(binlist, 15), 4096)
  end

  defp cluster_number(shard, clusters) do
    rem(shard, clusters)
  end
end