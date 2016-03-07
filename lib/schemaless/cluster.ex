defmodule Schemaless.Cluster do
  use GenServer

  def start_link({host, port, from, to, step, user}) do
    GenServer.start_link(__MODULE__, [host, port, from, to, step, user], name: name(from))
  end

  def init([host, port, from, to, step, user]) do
    IO.puts "Connecting to #{host}:#{port} as #{user} #{from}..#{to} step #{step}"
    {:ok, ro_conn} = Mariaex.Connection.start_link(username: user <> "_ro",
      port: 3306, skip_database: true)
    {:ok, rw_conn} = Mariaex.Connection.start_link(username: user <> "_rw",
      port: 3306, skip_database: true)
    {:ok, %{ro_conn: ro_conn, rw_conn: rw_conn}}
  end

  def name(cluster) do
    String.to_atom("Elixir.Schemaless.Cluster#{cluster}")
  end

  def get_cell(cluster, datastore, uuid) do
    name(cluster)
    |> GenServer.call({:get_cell, datastore, uuid})
  end

  def get_cell(cluster, datastore, uuid, column) do
    name(cluster)
    |> GenServer.call({:get_cell, datastore, uuid, column})
  end

  def get_cell(cluster, datastore, uuid, column, ref_key) do
    name(cluster)
    |> GenServer.call({:get_cell, datastore, uuid, column, ref_key})
  end

  def put_cell(cluster, datastore, uuid, column, ref_key, data) do
    name(cluster)
    |> GenServer.call({:put_cell, datastore, uuid, column, ref_key})
  end

  def handle_call({:get_cell, datastore, uuid}, _from, state) do
    IO.puts "From #{datastore} get #{uuid}"
    IO.inspect state[:ro_conn]
    {:reply, {:ok, %{"BASE": %{"1": "how low can you go down really"}}}, state}
  end

  def handle_call({:get_cell, datastore, uuid, column}, _from, state) do
    IO.puts "From #{datastore} get #{uuid} col #{column}"
    IO.inspect state[:ro_conn]
    {:reply, {:ok, %{"BASE": %{"1": "how low can you go down"}}}, state}
  end

  def handle_call({:get_cell, datastore, uuid, column, ref_key}, _from, state) do
    IO.puts "From #{datastore} get #{uuid} col #{column} ref #{ref_key}"
    IO.inspect state[:ro_conn]
    {:reply, {:ok, %{"BASE": %{"1": "how low can you go"}}}, state}
  end

  def handle_call({:put_cell, datastore, uuid, column, ref_key, data}, _from, state) do
    IO.puts "From #{datastore} get #{uuid} col #{column} ref #{ref_key}"
    IO.inspect state[:rw_conn]
    {:reply, {:error, "I cannot put"}, state}
  end
end