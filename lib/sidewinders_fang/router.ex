defmodule SidewindersFang.Router do
  # http://www.jarredtrost.com/category/elixir-plug/
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: SidewindersFang.Lib.JSON
  plug :match
  plug :dispatch

  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{status: "ok"}))
  end

  get "/access/:datastore/cell/:uuid/:column/:ref_key" do
    # IO.puts "get #{datastore}  #{uuid} #{column} #{ref_key}"
    {:ok, result} = Schemaless.get_cell(datastore, uuid, column, ref_key)
    send_get_cell_response(conn, result)
  end

  get "/access/:datastore/cell/:uuid/:column" do
    # IO.puts "get #{datastore}  #{uuid} #{column}"
    {:ok, result} = Schemaless.get_cell(datastore, uuid, column)
    send_get_cell_response(conn, result)
  end

  get "/access/:datastore/cell/:uuid" do
    # IO.puts "get #{datastore}  #{uuid}"
    {:ok, result} = Schemaless.get_cell(datastore, uuid)
    send_get_cell_response(conn, result)
  end

  defp send_get_cell_response(conn, []) do
    conn
    |> send_resp(404, "Not found")
  end

  defp send_get_cell_response(conn, result) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(result))
  end


  # {"rows":
  #  [{"uuid": uuid,
  #    "columns": [{"column_key": "my_column_a",
  #         "ref_key": "my_ref_key_a",
  #         "shard_key": "optional_shard_key",
  #         "data": {"thebase": 0}
  #     },
  #        {"column_key": "my_column_b",
  #         "ref_key": "my_ref_key_b",
  #         "shard_key": "optional_shard_key",
  #         "data": {"thefare": 1}
  #     }],
  #    "shard_key": "optional_shard_key"
  # }],
  #  "buffered": True|False        # Defaults to True
  #  "update_indexes": True|False  # Defaults to True
  #  "single_commit":  True|False  # Defaults to True
  #  "delay_indexing": True|False  # Defaults to False
  #  "enforce_single_commit": True|False  # Defaults to False
  # }
  # NOTE: If the datastore has shard_key enabled, it is preferred to put the
  # shard_key at the same level as the uuid; do not put it inside each column.

  # The "update_indexes" param controls if this put will be indexed.
  # The "buffered" param controls if this put can be buffered if necessary.
  # The "single_commit" param controls if a single db commit will be tried to write this put.
  # The "enforce_single_commit" param applies only if "single_commit" is True
  #     and "buffered" is False. It enforces the write in a single commit,
  #     any failures are reported back.
  # The "delay_indexing" param controls if the indexes process will be tried immediately,
  #     adding latency to this write, or done later by celery. A False value for update_indexes
  #     overrides the behavior of this parameter.

  # In case of a multi put cannot be carried out, each of the entities are tried individually.  To
  # see the status of individual entities consult the returned JSON that has the following format::

  #     {"rows":
  #       [{"uuid": uuid,
  #         "columns": [{"column_key": "my_cloumn_a",
  #                      "ref_key":    "my_ref_key_a",
  #                      "code": 409,                   # the status code (see below)
  #                      "msg": "Entity already exists" # The error message, if there was an error,
  #                     },
  #                       ...]},
  #        ...
  #       ]
  #     }

  # Note that the returned response code is the maximum of the status codes for each of the
  # entities (except 409s). E.g., entity 1 is a 200 and entity2 is a 409, the returned response
  # code for the HTTP call is 200.  If both entities are 409s, then 409 is returned (only).

  # Returns:

  #     * 200 - write succeeded and available for reads
  #     * 202 - write has been buffered in a DB but is not available for reads
  #       yet. (if buffered is False, then the call will fail rather than be
  #       buffered)

  # For a buffered write, the data will not be available to read immediately. If the
  # cell has already been written, the write will be silently ignored (e.g., if the
  # call would have resulted in a 409)

  # Failures:

  #     * 400 - Bad parameters (e.g., malformed UUID)
  #     * 409 - Entity already exists. In this case, the list of duplicate columns will be returned
  #     * 503 - Database is unavailable

  put "/access/:datastore/cells" do
    results = Enum.map(conn.body_params["rows"], fn(col) -> put_row(datastore, col) end)
    {status, response} = compose_response(conn.body_params["rows"], results)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{rows: response}))
  end

  defp put_row(datastore, %{"uuid" => uuid, "columns" => columns}) do
    Schemaless.put_cell(datastore, uuid, columns)
  end

  defp compose_response(rows, results) do
    compose_response_row_level(
      200, # Start with assuming success.
      rows,
      results,
      [])
  end

  defp compose_response_row_level(
        status, [row|rows], [result|results], acc)
    do
    {status, row_level_messages} =
      compose_response_column_level(
        status,
        row["uuid"],
        row["columns"],
        result,
        []
      )
    compose_response_row_level(
      status,
      rows,
      results,
      [
        %{uuid: row["uuid"],
          columns: row_level_messages
         }
      ] ++ acc)
  end

  defp compose_response_row_level(status, [], [], acc) do
     {status, acc}
  end

  defp compose_response_column_level(
        status, uuid, [column|columns], [{:error, :duplicate}|results], acc)
    do
    compose_response_column_level(
      409, # The overall return code is 409 now.
      uuid,
      columns,
      results,
      [
        %{column_key: column["column_key"],
          ref_key: column["ref_key"],
          code: 409,
          msg: "Entity already exists"}
      ] ++ acc)
  end

  defp compose_response_column_level(
        status, uuid, [column|columns], [{:error, _}|results], acc)
    do
    compose_response_column_level(
      500, # The overall return code is 500 now.
      uuid,
      columns,
      results,
      [
        %{column_key: column["column_key"],
          ref_key: column["ref_key"],
          code: 500,
          msg: "Error during entity write"}
      ] ++ acc)
  end

  defp compose_response_column_level(
        status, uuid, [column|columns], [result|results], acc)
    do
    compose_response_column_level(
      status, uuid,
      columns, results,
      [
        %{column_key: column["column_key"],
          ref_key: column["ref_key"],
          code: 200,
          msg: "OK"
         }
      ] ++ acc)
  end

  defp compose_response_column_level(
        status, uuid, [], [], acc) do
     {status, acc}
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
