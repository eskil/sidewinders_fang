defmodule Schemaless.Datastore do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def init(arg) do
    {:ok, arg}
  end

  def get_cell(datastore, uuid) do
    {:ok, %{"BASE": %{"1": "how low can you go"}}}
  end

  def get_cell(datastore, uuid, column) do
    {:ok, %{"BASE": %{"1": "how low can you go"}}}
  end

  def get_cell(datastore, uuid, column, ref_key) do
    {:ok, %{"BASE": %{"1": "how low can you go"}}}
  end
end