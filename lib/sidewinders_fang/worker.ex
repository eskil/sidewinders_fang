defmodule SidewindersFang.Worker do
  def start_link do
    Plug.Adapters.Cowboy.http(
      SidewindersFang.Router,
      [],
      port: Application.get_env(:sidewinders_fang, :port)
    )
  end
end