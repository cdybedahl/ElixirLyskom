defmodule Lyskom do

  @server Lyskom.Server

  def login(name, password) do
    GenServer.call(@server, {:login, name, password})
  end

end
