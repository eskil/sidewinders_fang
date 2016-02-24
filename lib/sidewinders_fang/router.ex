defmodule SidewindersFang.Router do
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
    {:ok, result} = Schemaless.Datastore.get_cell(:datastore, :uuid, :column, :ref_key)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, uuid: uuid, column: column, ref_key: ref_key, result: result}))
  end

  get "/access/:datastore/cell/:uuid/:column" do
    {:ok, result} = Schemaless.Datastore.get_cell(:datastore, :uuid, :column)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, uuid: uuid, column: column, result: result}))
  end

  get "/access/:datastore/cell/:uuid" do
    {:ok, result} = Schemaless.Datastore.get_cell(:datastore, :uuid)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, uuid: uuid, result: result}))
  end

  put "/access/:datastore/cells" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, body: conn.body_params}))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end