defmodule Lyskom.Server do
  use GenServer

  require Logger

  @me __MODULE__

  ### API

  def start_link(name_base) do
    GenServer.start_link(@me, name_base, name: _name(name_base))
  end

  def incoming(msg, name_base) do
    # Logger.debug("Got a message: #{inspect(msg)}")
    GenServer.cast(_name(name_base), {:incoming, msg})
  end

  ### Callbacks

  def init(name_base) do
    {:ok, %{name_base: name_base, next_call_id: 1, pending: %{}}}
  end

  def terminate(_reason, state) do
    Enum.each(state.pending, fn {_id, {_call, from, _data}} -> GenServer.reply(from, :retry) end)
  end

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:server, ref}}}
  end

  #############################################################################
  ## Handle calls
  #############################################################################

  def handle_call(msg, from, state) do
    Lyskom.Server.Handle.call(msg, from, state)
  end

  #############################################################################
  ## Handle casts
  #############################################################################

  def handle_cast({:incoming, [:async, _argcount, type | args]}, state) do
    Lyskom.AsyncHandler.handle(type, args, state.name_base)

    {:noreply, state}
  end

  def handle_cast({:incoming, [type, id | args]}, state) do
    id = List.to_integer(id)

    case Map.fetch(state.pending, id) do
      {:ok, {call, from, call_args}} ->
        Lyskom.Server.Process.response(call, type, from, args, call_args, state.name_base)
        {:noreply, put_in(state.pending, Map.delete(state.pending, id))}

      :error ->
        Logger.debug("Unexpected response: #{type} #{id} #{inspect(args)}")
    end
  end

  #############################################################################
  ## Handle random messages
  #############################################################################

  def handle_info(something, state) do
    Logger.info("Got message: #{inspect(something)}")
    {:noreply, state}
  end
end
