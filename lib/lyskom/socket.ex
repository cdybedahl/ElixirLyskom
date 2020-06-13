defmodule Lyskom.Socket do
  use GenServer, restart: :temporary

  require Logger
  alias Lyskom.Socket

  defstruct host: "",
            port: 0,
            socket: nil,
            sockbuf: "",
            tok_data: "",
            tok_acc: [],
            tok_state: :start,
            msg_acc: [],
            messages: [],
            next_call_id: 1,
            outstanding_calls: %{}

  ### API

  def start_link([host, port]) do
    GenServer.start_link(__MODULE__, %Socket{host: host, port: port})
  end

  def incoming_data(pid, str) do
    GenServer.cast(pid, {:incoming_data, str})
  end

  def incoming_token(pid, token) do
    GenServer.cast(pid, {:incoming_token, token})
  end

  def incoming_msg(pid, msg) do
    GenServer.cast(pid, {:incoming_msg, msg})
  end

  def send(msg, pid) do
    :gen_tcp.send(pid, msg)
  end

  ### Callbacks

  @impl true
  def init(state) do
    case :gen_tcp.connect(
           to_charlist(state.host),
           state.port,
           [:binary, active: false]
         ) do
      {:ok, socket} ->
        :ok = :gen_tcp.send(socket, "A6HElixir")
        {:ok, "LysKOM\n"} = :gen_tcp.recv(socket, 0)
        :ok = :inet.setopts(socket, active: :once)
        {:ok, %Socket{state | socket: socket}}

      {:error, msg} ->
        {:stop, msg}
    end
  end

  ## Parser-related functions.

  @impl true
  def handle_cast({:incoming_data, msg}, state) do
    {:noreply, Lyskom.Tokenize.incoming(state, msg)}
  end

  def handle_cast({:incoming_token, token}, state) do
    case token do
      :msgend ->
        msg =
          state.msg_acc
          |> Enum.reverse()
          |> Lyskom.Tokenize.process_arrays()

        incoming_msg(self(), msg)
        {:noreply, %Socket{state | msg_acc: []}}

      _ ->
        {:noreply, Map.update!(state, :msg_acc, fn t -> [token | t] end)}
    end
  end

  def handle_cast({:incoming_msg, msg}, state) do
    {:noreply, Lyskom.Responses.handle(msg, state)}
  end

  ## Socket-related functions.
  @impl true
  def handle_info({:tcp, socket, msg}, state = %Socket{socket: socket}) do
    :ok = :inet.setopts(socket, active: :once)
    incoming_data(self(), msg)
    {:noreply, state}
  end

  ## External-API-related functions
  @impl true
  def handle_call({:call, payload}, from, state) do
    {:noreply, Lyskom.Calls.send(payload, from, state)}
  end
end
