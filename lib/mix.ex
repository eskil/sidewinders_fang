defmodule Mix.Tasks.SidewindersFang do

  defmodule ResetDb do
    use Mix.Task
    @shortdoc "This is short documentation, see"

    @moduledoc """
    A test task.
    """
    def run(_) do
      {:ok, rw_conn} = :mysql.start_link([
        user: "sfang_admin",
        password: "password"
      ])
      Enum.map(0..4095, fn(shard) -> create_tables(shard, rw_conn) end)
    end

    def create_tables(shard, rw_conn) do
      IO.puts "ReCreating #{shard}"
      :ok = :mysql.query(rw_conn, """
      DROP DATABASE IF EXISTS mez_shard#{shard}
      """)
      :ok = :mysql.query(rw_conn, """
         CREATE DATABASE IF NOT EXISTS mez_shard#{shard}
       """)
    table = """
         CREATE TABLE IF NOT EXISTS mez_shard#{shard}.trips (
	 `added_id` int(11) NOT NULL AUTO_INCREMENT,
	 `row_key` binary(16) NOT NULL,
	 `column_key` varchar(191) CHARACTER SET utf8mb4 NOT NULL,
	 `ref_key` bigint(20) NOT NULL,
	 `updated` timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
	 `body` mediumblob NOT NULL,
	 PRIMARY KEY (`added_id`),
	 UNIQUE KEY `uc_key` (`row_key`,`column_key`,`ref_key`),
	 KEY `updated_idx` (`updated`),
	 KEY `column_key_idx` (`column_key`)
	 )
	 """
      :ok = :mysql.query(rw_conn, table)
      end
  end
end
