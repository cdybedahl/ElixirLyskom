defmodule Lyskom do

  @server Lyskom.Server

  def login(name, password) do
    GenServer.call(@server, {:login, name, password}, :infinity)
  end

end
