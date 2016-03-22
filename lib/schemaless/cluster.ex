defmodule Schemaless.Cluster do
  use GenServer
  use Calendar

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    host = args[:host]
    port = args[:port]
    user = args[:user]
    from = args[:cluster]
    to = args[:to]
    step = args[:step]
    {:ok, ro_conn} = :mysql.start_link([
      user: user <> "_ro",
      port: port,
      password: "password"
    ])
    {:ok, rw_conn} = :mysql.start_link([
      user: user <> "_rw",
      port: port,
      password: "password"
    ])
    {:ok, %{ro_conn: ro_conn, rw_conn: rw_conn}}
  end

  def handle_call({:get_cell, shard, datastore, uuid}, _from, state) do
    database = "mez_shard#{shard}"
    {:ok, result} = :mysql.query(state[:ro_conn],
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
    {:ok, result} = :mysql.query(state[:ro_conn],
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
    {:ok, result} = :mysql.query(state[:ro_conn],
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
      Map.merge(
				data,
        %{"_ref_key" => ref_key,
          "_column_key" => column_key,
          "_updated_at" => updated |> Strftime.strftime!("%FT%TZ")
         }
			)
    end
  end

  def handle_call({:put_cell, shard, datastore, uuid, columns}, _from, state) do
    results = Enum.map(columns, fn(col) ->
      put_a_cell(state[:rw_conn], shard, datastore, uuid, col)
    end)
    results = for result <- results do
      IO.inspect result
    end
    {:reply, results, state}
  end

  defp put_a_cell(
        conn, shard, datastore, uuid,
        %{"column_key" => column_key,
          "ref_key" => ref_key,
          "data" => data
         }
			)
    do
    {:ok, body} = MessagePack.pack(data)
    body = :erlbz2.compress(body)
    Mariaex.Connection.query(conn, """
      INSERT INTO mez_shard#{shard}.#{datastore} (row_key, column_key, ref_key, body)
      VALUES (unhex(replace(?,'-','')), ?, ?, ?)
      """, [uuid, column_key, ref_key, body])
  end
end
