defmodule Lyskom.Socket do
  use GenServer
  require Logger

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, Application.get_env(:lyskom, :server), name: @me)
  end

  def send(msg) do
    GenServer.call(@me, {:send, msg})
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

  ## Handle calls

  def handle_call({:send, msg}, _from, state = %{socket: socket}) do
    :gen_tcp.send(socket,msg)
    {:reply, :ok, state}
  end

  ## Handle random messages

  def handle_info(msg, state) do
    Logger.info("Got from server: " <> inspect(msg))
    {:noreply, state}
  end

end
