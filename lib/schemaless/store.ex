defmodule Schemaless.Store do

  def get_cell(datastore, uuid) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    Schemaless.Cluster.get_cell(cluster, shard, datastore, uuid)
  end

  def get_cell(datastore, uuid, column) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    Schemaless.Cluster.get_cell(cluster, shard, datastore, uuid, column)
  end

  def get_cell(datastore, uuid, column, ref_key) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    Schemaless.Cluster.get_cell(cluster, shard, datastore, uuid, column, ref_key)
  end

  def put_cell(datastore, uuid, columns) do
    {cluster, shard} = Schemaless.Config.shard_and_cluster_for_uuid(uuid)
    Schemaless.Cluster.put_cell(cluster, shard, datastore, uuid, columns)
  end

end
