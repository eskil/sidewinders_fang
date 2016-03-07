defmodule Schemaless.Access do
  use GenServer
  use Bitwise

  def start_link(config) do
    IO.inspect(config)
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    {:ok, config}
  end

  def get_cell(datastore, uuid) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid})
  end

  def handle_call({:get_cell, datastore, uuid}, _from, state) do
    IO.puts cluster_name(uuid)
  end

  def get_cell(datastore, uuid, column) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid, column})
  end

  def handle_call({:get_cell, datastore, uuid, column}, _from, state) do
    IO.puts datastore
    IO.puts uuid
    IO.puts column
    IO.puts UUID.string_to_binary!(uuid)
    {:reply, {:ok, %{"BASE": %{"1": "how low can you go"}}}, state}
  end

  def get_cell(datastore, uuid, column, ref_key) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid, column, ref_key})
  end

  def handle_call({:get_cell, datastore, uuid, column, ref_key}, _from, state) do
    IO.puts datastore
    IO.puts uuid
    IO.puts column
    IO.puts ref_key
    IO.puts UUID.string_to_binary!(uuid)
    {:ok, %{"BASE": %{"1": "how low can you go"}}}
  end

  def cluster_name(uuid) do
    uuid_info = UUID.info!(uuid)
    binlist = :binary.bin_to_list(uuid_info[:binary])
    shard_number = rem((Enum.at(binlist, 14) <<< 8) + Enum.at(binlist, 15), 4096)
    from = 10
    String.to_atom("Cluster#{from}")
  end

end