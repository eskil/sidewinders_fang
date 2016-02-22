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
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, uuid: uuid, column: column, ref_key: ref_key}))
  end

  get "/access/:datastore/cell/:uuid/:column" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, uuid: uuid, column: column}))
  end

  get "/access/:datastore/cell/:uuid" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, SidewindersFang.Lib.JSON.encode!(%{datastore: datastore, uuid: uuid}))
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