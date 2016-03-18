defmodule Schemaless.Cluster do
  use GenServer
  use Calendar

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
    database = "mez_shard#{shard}"
    {:ok, result} = Mariaex.Connection.query(state[:ro_conn],
      "SELECT updated, column_key, ref_key, body " <>
      "FROM #{database}.#{datastore} " <>
      "WHERE row_key = unhex(replace(?,'-',''))", [uuid])
    rows = for row <- unpack_rows(result) do
      Map.merge(row, %{"_dbname" => database, "_row_key" => uuid})
    end
    {:reply, {:ok, rows}, state}
  end

  def handle_call({:get_cell, shard, datastore, uuid, column}, _from, state) do
    database = "mez_shard#{shard}"
    {:ok, result} = Mariaex.Connection.query(state[:ro_conn],
      "SELECT updated, column_key, ref_key, body " <>
      "FROM #{database}.#{datastore} " <>
      "WHERE row_key = unhex(replace(?,'-','')) " <>
      "  AND column_key = ?", [uuid, column])
    rows = for row <- unpack_rows(result) do
      Map.merge(row, %{"_dbname" => database, "_row_key" => uuid})
    end
    {:reply, {:ok, rows}, state}
  end

  def handle_call({:get_cell, shard, datastore, uuid, column, ref_key}, _from, state) do
    database = "mez_shard#{shard}"
    {:ok, result} = Mariaex.Connection.query(state[:ro_conn],
      "SELECT updated, column_key, ref_key, body " <>
      "FROM #{database}.#{datastore} " <>
      "WHERE row_key = unhex(replace(?,'-','')) " <>
      "  AND column_key = ? " <>
      "  AND ref_key = ?", [uuid, column, ref_key])
    rows = for row <- unpack_rows(result) do
      Map.merge(row, %{"_dbname" => database, "_row_key" => uuid})
    end
    {:reply, {:ok, rows}, state}
  end

  defp unpack_rows(result)do
    for [updated, column_key, ref_key, body] <- result.rows do
      {:ok, data} = body
      |> :erlbz2.decompress
      |> MessagePack.unpack
      Map.merge(data, %{
        "_ref_key" => ref_key,
	"_column_key" => column_key,
	"_updated_at" => updated |> Strftime.strftime!("%FT%TZ")
      })
    end
  end

  # This needs to be hooked up in the route if single_commit: true is set.
  def handle_call({:put_cell_txn, shard, datastore, uuid, columns}, _from, state) do
    # IO.puts "Into #{datastore}.#{shard} get #{uuid} col in 1 txn"
    # IO.inspect columns
    try do
      result = Mariaex.transaction(state[:rw_conn], fn(conn) ->
        Enum.map(columns, fn(col) -> put_a_cell(conn, shard, datastore, uuid, col) end)
      end)
      {:reply, result, state}
    rescue
      e in Mariaex.Error ->
        case e.mariadb.code do
          1062 -> {:reply, {:error, :duplicate}, state}
          _ -> {:reply, {:error, e.mariadb.code}, state}
        end
      e ->
        {:reply, {:error, e}, state}
    end
  end

  def handle_call({:put_cell, shard, datastore, uuid, columns}, _from, state) do
    results = Enum.map(columns, fn(col) ->
      put_a_cell(state[:rw_conn], shard, datastore, uuid, col)
    end)
    results = for result <- results do
      case result do
        {:ok, %Mariaex.Result{num_rows: 1}} -> {:ok, 1}
	{:error, %Mariaex.Error{mariadb: %{code: 1062}}} -> {:error, :duplicate}
	_ -> {:error, :unknown}
      end
    end
    {:reply, results, state}
  end

  defp put_a_cell(
				conn, shard, datastore, uuid,
				%{"column_key" => column_key, "ref_key" => ref_key, "data" => data})
		do
    {:ok, body} = MessagePack.pack(data)
    body = :erlbz2.compress(body)
    Mariaex.Connection.query(conn, """
      INSERT INTO mez_shard#{shard}.#{datastore} (row_key, column_key, ref_key, body)
      VALUES (unhex(replace(?,'-','')), ?, ?, ?)
      """, [uuid, column_key, ref_key, body])
  end
end
