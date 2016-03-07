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

  def handle_call({:get_cell, datastore, uuid}, _from, state) do
    cn = cluster_number(uuid, state[:clusters])
    {:reply, Schemaless.Cluster.get_cell(cn, datastore, uuid), state}
  end

  def handle_call({:get_cell, datastore, uuid, column}, _from, state) do
    cn = cluster_number(uuid, state[:clusters])
    {:reply, Schemaless.Cluster.get_cell(cn, datastore, uuid, column), state}
  end

  def handle_call({:get_cell, datastore, uuid, column, ref_key}, _from, state) do
    cn = cluster_number(uuid, state[:clusters])
    {:reply, Schemaless.Cluster.get_cell(cn, datastore, uuid, column, ref_key), state}
  end

  def cluster_number(uuid, clusters) do
    binlist = UUID.info!(uuid)[:binary]
    |> :binary.bin_to_list

    rem((Enum.at(binlist, 14) <<< 8) + Enum.at(binlist, 15), 4096)
    |> rem(clusters)
  end
end