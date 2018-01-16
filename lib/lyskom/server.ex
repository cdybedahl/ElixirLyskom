defmodule Lyskom.Server do
  use GenServer

  require Logger

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def incoming(msg) do
    Logger.debug("Got a message: #{inspect msg}")
    GenServer.cast(@me, {:incoming, msg})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{next_call_id: 1, pending: %{} }}
  end

  ## Handle calls
  def handle_call({:login, id_number, password, invisible}, from, state = %{next_call_id: next_id}) do
    prot_a_string = "#{next_id} 62 #{id_number} #{hollerith(password)} #{boolean(invisible)}\n"
    Logger.info("Sending: " <> prot_a_string)
    state = put_in state.next_call_id, next_id + 1
    state = put_in state.pending[next_id], {:login, from}
    Lyskom.Socket.send(prot_a_string)
    {:noreply, state}
  end

  ## Handle casts
  def handle_cast({:incoming, [:async, argcount, type | args]}, state) do
    Logger.info("Got async message type #{type} with #{argcount} arguments (#{inspect(args)}).")
    {:noreply, state}
  end

  def handle_cast({:incoming, [type, id | args]}, state) do
    {call, from} = Map.fetch!(state.pending, id)
    state = put_in(state.pending, Map.delete(state.pending, id))
    process_response(call, type, from, args)
    {:noreply, state}
  end

  ## Handle random messages
  def handle_info(something, state) do
    Logger.info "Got message: #{inspect(something)}"
    {:noreply, state}
  end

  ## Processing responses. Maybe should be in a separate module.
  def process_response(:login, :success, from, []) do
    GenServer.reply(from,:ok)
  end

  def process_response(:login, :failure, from, args) do
    GenServer.reply(from,{:error, args})
  end

  # Does not belong here. Move to types file later.
  def hollerith(str) do
    "#{String.length(str)}H#{str}"
  end

  def boolean(true) do
    1
  end

  def boolean(false) do
    0
  end

end
