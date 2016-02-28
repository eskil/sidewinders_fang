defmodule Schemaless.Datastore do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, ro_conn} = Mariaex.Connection.start_link(username: "sfang_ro", database: "sidewinders_fang")
    {:ok, rw_conn} = Mariaex.Connection.start_link(username: "sfang_rw", database: "sidewinders_fang")
    {:ok, %{ro_conn: ro_conn, rw_conn: rw_conn}}
  end

  def get_cell(datastore, uuid) do
    GenServer.call(__MODULE__, {:get_cell, datastore, uuid})
  end

  def handle_call({:get_cell, datastore, uuid}, _from, state) do
    ro_conn = state[:ro_conn]
    IO.puts datastore
    IO.puts uuid
    IO.puts ro_conn
    IO.puts UUID.string_to_binary!(uuid)
    {:reply, {:ok, %{"BASE": %{"1": "how low can you go"}}}, state}
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
end