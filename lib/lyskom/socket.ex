defmodule Lyskom.Socket do
  use GenServer

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, Application.get_env(:lyskom, :server), name: @me)
  end

  ### Callbacks

  def init(state) do
    %{host: host, port: port} = state
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, active: false])
    :ok = :gen_tcp.send(socket, "A6HElixir")
    {:ok, "LysKOM\n"} = :gen_tcp.recv(socket,0)
    :ok = :inet.setopts(socket, active: :once)
    {:ok, Map.put(state, :socket, socket)}
  end

end
