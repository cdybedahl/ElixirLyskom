defmodule Lyskom do

  @server Lyskom.Server

  def login(id_number, password, invisible \\ false) do
    GenServer.call(@server, {:login, id_number, password, invisible}, :infinity)
  end

  def logout do
    GenServer.call(@server, {:logout}, :infinity)
  end

end
