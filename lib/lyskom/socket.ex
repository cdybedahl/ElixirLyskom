defmodule Lyskom.Socket do
  use GenServer
  require Logger

  @me __MODULE__

  ### API

  def start_link([name_base, host, port]) do
    state = %{host: host, port: port}
    GenServer.start_link(@me, Map.put(state, :name_base, name_base), name: _name(name_base))
  end

  def send(msg, name) do
    GenServer.call(_name(name), {:send, msg})
  end

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:socket, ref}}}
  end

  ### Callbacks

  def init(state = %{host: host, port: port}) do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, active: false])
    :ok = :gen_tcp.send(socket, "A6HElixir")
    {:ok, "LysKOM\n"} = :gen_tcp.recv(socket, 0)
    :ok = :inet.setopts(socket, active: :once)
    Logger.debug("Connection to server established.")
    {:ok, Map.put(state, :socket, socket)}
  end

  ## Handle calls

  def handle_call({:send, msg}, _from, state = %{socket: socket}) do
    :ok = :gen_tcp.send(socket, msg)
    # Logger.debug("Sent: #{msg}")
    {:reply, :ok, state}
  end

  ## Handle random messages

  def handle_info({:tcp, socket, msg}, state = %{socket: socket, name_base: name_base}) do
    # Logger.debug("Incoming: #{msg}")
    Lyskom.ProtA.Tokenize.incoming(msg, name_base)
    :ok = :inet.setopts(socket, active: :once)
    {:noreply, state}
  end
end
