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

  match _ do
    send_resp(conn, 404, "oops")
  end
end