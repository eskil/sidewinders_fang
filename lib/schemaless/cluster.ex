defmodule Schemaless.Cluster do
  use GenServer

  def start_link({host, port, from, to, step, user}) do
    GenServer.start_link(__MODULE__, [host, port, from, to, step, user], name: name(from))
  end

  def init([host, port, from, to, step, user]) do
    IO.puts "Connecting to #{host}:#{port} as #{user} #{from}..#{to} step #{step}"
    {:ok, ro_conn} = Mariaex.Connection.start_link(username: user <> "_ro", port: 3306, skip_database: true)
    {:ok, rw_conn} = Mariaex.Connection.start_link(username: user <> "_rw", port: 3306, skip_database: true)
    {:ok, %{ro_conn: ro_conn, rw_conn: rw_conn}}
  end

  def name(cluster) do
    String.to_atom("Elixir.Schemaless.Cluster#{cluster}")
  end

  def get_cell(cluster, shard, datastore, uuid) do
    name(cluster)
    |> GenServer.call({:get_cell, shard, datastore, uuid})
  end

  def get_cell(cluster, shard, datastore, uuid, column) do
    name(cluster)
    |> GenServer.call({:get_cell, shard, datastore, uuid, column})
  end

  def get_cell(cluster, shard, datastore, uuid, column, ref_key) do
    name(cluster)
    |> GenServer.call({:get_cell, shard, datastore, uuid, column, ref_key})
  end

  def put_cell(cluster, shard, datastore, uuid, columns) do
    name(cluster)
    |> GenServer.call({:put_cell, shard, datastore, uuid, columns})
  end

  def handle_call({:get_cell, shard, datastore, uuid}, _from, state) do
    {:ok, result} = Mariaex.Connection.query(state[:ro_conn], "SELECT column_key, ref_key, body FROM mez_shard#{shard}.#{datastore} WHERE row_key = unhex(replace(?,'-',''))", [uuid])
    {:reply, {:ok, load_rows(result)}, state}
  end

  def handle_call({:get_cell, shard, datastore, uuid, column}, _from, state) do
    {:ok, result} = Mariaex.Connection.query(state[:ro_conn], "SELECT column_key, ref_key, body FROM mez_shard#{shard}.#{datastore} WHERE row_key = unhex(replace(?,'-','')) AND column_key = ?", [uuid, column])
    {:reply, {:ok, load_rows(result)}, state}
  end

  def handle_call({:get_cell, shard, datastore, uuid, column, ref_key}, _from, state) do
    {:ok, result} = Mariaex.Connection.query(state[:ro_conn], "SELECT column_key, ref_key, body FROM mez_shard#{shard}.#{datastore} WHERE row_key = unhex(replace(?,'-','')) AND column_key = ? AND ref_key = ?", [uuid, column, ref_key])
    {:reply, {:ok, load_rows(result)}, state}
  end

  def handle_call({:put_cell, shard, datastore, uuid, columns}, _from, state) do
    # IO.puts "Into #{datastore}.#{shard} get #{uuid} col"
    # IO.inspect columns
    result = Mariaex.transaction(state[:rw_conn], fn(conn) ->
      Enum.map(columns, fn(col) -> put_cell_in_txn(conn, shard, datastore, uuid, col) end)
    end)
    {:reply, result, state}
  end

  defp put_cell_in_txn(conn, shard, datastore, uuid, %{"column_key" => column_key, "ref_key" => ref_key, "data" => data}) do
    {:ok, body} = MessagePack.pack(data)
    cbody = :erlbz2.compress(body)
    Mariaex.Connection.query!(conn, """
      INSERT INTO mez_shard#{shard}.#{datastore} (row_key, column_key, ref_key, body)
      VALUES (unhex(replace(?,'-','')), ?, ?, ?)
      """, [uuid, column_key, ref_key, cbody])
  end

  defp load_rows(result)do
    for [column_key, ref_key, body] <- result.rows do
      {:ok, data} = body
      |> :erlbz2.decompress
      |> MessagePack.unpack
      %{column_key => %{"data" => data, "ref_key" => ref_key}}
    end
  end
end