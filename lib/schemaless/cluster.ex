defmodule Schemaless.Cluster do
  use GenServer

  def start_link({host, port, from, to, step, user}) do
    name = String.to_atom("Cluster#{from}")
    GenServer.start_link(__MODULE__, [host, port, from, to, step, user], name: name)
  end

  def init([host, port, from, to, step, user]) do
    IO.puts "Connecting to #{host}:#{port} as #{user} #{from}..#{to} step #{step}"
    {:ok, ro_conn} = Mariaex.Connection.start_link(username: user <> "_ro", port: 3306, skip_database: true)
    {:ok, rw_conn} = Mariaex.Connection.start_link(username: user <> "_rw", port: 3306, skip_database: true)
    {:ok, %{ro_conn: ro_conn, rw_conn: rw_conn}}
  end
end