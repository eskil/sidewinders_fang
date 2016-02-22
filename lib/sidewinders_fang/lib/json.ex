defmodule SidewindersFang.Lib.JSON do
  def decode!(data) do
    :jiffy.decode(data, [:return_maps])
  end

  def encode!(data) do
    :jiffy.encode(data)
  end
end