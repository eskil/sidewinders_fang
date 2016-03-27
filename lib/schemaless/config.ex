defmodule Schemaless.Config do
  use Bitwise

  def config do
    %{shards: 4096,
      clusters: 16}
  end

  def driver do
    case Application.get_env(:sidewinders_fang, :driver) do
      :mariaex -> Schemaless.Cluster.Mariaex
      :mysql_otp -> Schemaless.Cluster.MySQL_OTP
    end
  end

  def shard_number(uuid) do
    binlist = UUID.info!(uuid)[:binary]
    |> :binary.bin_to_list
    rem((Enum.at(binlist, 14) <<< 8) + Enum.at(binlist, 15), config[:shards])
  end

  def cluster_number(shard) do
    rem(shard, config[:clusters])
  end

  def shard_and_cluster_for_uuid(uuid) do
    shard = shard_number(uuid)
    cluster = cluster_number(shard)
    {cluster, shard}
  end
end
