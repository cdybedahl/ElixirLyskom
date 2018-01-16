defmodule Lyskom do

  @server Lyskom.Server

  def login(id_number, password) do
    GenServer.call(@server, {:login, id_number, password}, :infinity)
  end

end
