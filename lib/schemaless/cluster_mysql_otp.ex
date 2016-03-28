defmodule Schemaless.Cluster.MySQL_OTP do
  use GenServer
  use Calendar

  def start_link(args) do
    case Application.get_env(:sidewinders_fang, :poolboy) do
      :true ->
        GenServer.start_link(__MODULE__, args)
      _ ->
        GenServer.start_link(__MODULE__, args, name: name(args[:cluster]))
    end
  end

  def init(args) do
    host = args[:host]
    port = args[:port]
    user = args[:user]
    password = args[:password]
    from = args[:cluster]
    to = args[:to]
    step = args[:step]
    name = case Application.get_env(:sidewinders_fang, :poolboy) do
             :true ->
               "unnamed"
             _ ->
               name(from)
           end
    IO.puts "MySQL-OTP Connecting to #{host}:#{port} as #{user} #{from}..#{to} step #{step} as #{name}"
    {:ok, ro_conn} = :mysql.start_link([
      user: user <> "_ro",
      port: port,
      password: password
    ])
    {:ok, rw_conn} = :mysql.start_link([
      user: user <> "_rw",
      port: port,
      password: password
    ])
    {:ok, %{ro_conn: ro_conn, rw_conn: rw_conn}}
  end

  def name(cluster) do
    String.to_atom("Elixir.Schemaless.Cluster.MySQL_OTP#{cluster}")
  end

  def get_cell(cluster, shard, datastore, uuid) do
    IO.puts "GET CELL #{cluster} #{shard} #{datastore}"
    name(cluster)
    |> GenServer.call({:get_cell, shard, datastore, uuid})
  end

  def get_cell(cluster, shard, datastore, uuid, column) do
    IO.puts "GET CELL #{cluster} #{shard} #{datastore}"
    name(cluster)
    |> GenServer.call({:get_cell, shard, datastore, uuid, column})
  end

  def get_cell(cluster, shard, datastore, uuid, column, ref_key) do
    IO.puts "GET CELL #{cluster} #{shard} #{datastore}"
    name(cluster)
    |> GenServer.call({:get_cell, shard, datastore, uuid, column, ref_key})
  end

  def put_cell(cluster, shard, datastore, uuid, columns) do
    IO.puts "PUT ELL #{cluster} #{shard} #{datastore}"
    name(cluster)
    |> GenServer.call({:put_cell, shard, datastore, uuid, columns})
  end

  def handle_call({:get_cell, shard, datastore, uuid}, _from, state) do
    database = "mez_shard#{shard}"
    {:ok, _columns, rows} = :mysql.query(
      state[:ro_conn],
      "SELECT updated, column_key, ref_key, body " <>
        "FROM #{database}.#{datastore} " <>
        "WHERE row_key = unhex(replace(?,'-',''))", [uuid])
    rows = for row <- unpack_rows(rows) do
      Map.merge(row, %{"_dbname" => database, "_row_key" => uuid})
    end
    {:reply, {:ok, rows}, state}
  end

  def handle_call({:get_cell, shard, datastore, uuid, column}, _from, state) do
    database = "mez_shard#{shard}"
    {:ok, _columns, rows} = :mysql.query(state[:ro_conn],
      "SELECT updated, column_key, ref_key, body " <>
      "FROM #{database}.#{datastore} " <>
      "WHERE row_key = unhex(replace(?,'-','')) " <>
      "  AND column_key = ?", [uuid, column])
    rows = for row <- unpack_rows(rows) do
      Map.merge(row, %{"_dbname" => database, "_row_key" => uuid})
    end
    {:reply, {:ok, rows}, state}
  end

  def handle_call({:get_cell, shard, datastore, uuid, column, ref_key}, _from, state) do
    database = "mez_shard#{shard}"
    {:ok, _columns, rows} = :mysql.query(state[:ro_conn],
      "SELECT updated, column_key, ref_key, body " <>
      "FROM #{database}.#{datastore} " <>
      "WHERE row_key = unhex(replace(?,'-','')) " <>
      "  AND column_key = ? " <>
      "  AND ref_key = ?", [uuid, column, ref_key])
    rows = for row <- unpack_rows(rows) do
      Map.merge(row, %{"_dbname" => database, "_row_key" => uuid})
    end
    {:reply, {:ok, rows}, state}
  end

  def handle_call({:put_cell, shard, datastore, uuid, columns}, _from, state) do
    results = Enum.map(columns, fn(col) ->
      put_a_cell(state[:rw_conn], shard, datastore, uuid, col)
    end)
    {:reply, results, state}
  end

  defp unpack_rows(rows)do
    for [updated, column_key, ref_key, body] <- rows do
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
    case :mysql.query(conn, """
      INSERT INTO mez_shard#{shard}.#{datastore} (row_key, column_key, ref_key, body)
      VALUES (unhex(replace(?,'-','')), ?, ?, ?)
      """, [uuid, column_key, ref_key, body]) do
      {:error, {1062, _, _}} ->
        {:error, :duplicate}
      {:error, _} ->
        {:error, :duplicate}
      :ok ->
        {:ok, 1}
    end
  end
end
