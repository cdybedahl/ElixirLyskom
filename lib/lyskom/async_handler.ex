defmodule Lyskom.AsyncHandler do
  use GenServer
  require Logger

  import Lyskom.ProtA.Async

  @me __MODULE__

  #############################################################################
  ### API
  #############################################################################

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def handle(type, args) do
    GenServer.cast(@me, {async(type), args})
  end

  def add_client(pid) do
    GenServer.call(@me, {:add_client, pid})
  end

  def remove_client(pid) do
    GenServer.call(@me, {:remove_client, pid})
  end

  #############################################################################
  ### Callbacks
  #############################################################################

  def init(:no_args) do
    {:ok, %{clients: MapSet.new()}}
  end

  def handle_cast({:async_new_text_old, [text_no | text_stat_old]}, state) do
    stat = Lyskom.ProtA.Type.TextStat.old(text_stat_old)
    Logger.info("New text #{text_no}: #{inspect(stat)}")
    send_to_clients(state.clients, {:async_new_text_old, List.to_integer(text_no), stat})
    {:noreply, state}
  end

  def handle_cast({:async_sync_db, []}, state) do
    Logger.info("Database synchronizing.")
    send_to_clients(state.clients, {:async_sync_db})
    {:noreply, state}
  end

  def handle_cast({type, args}, state) do
    Logger.info("Async #{inspect(type)} (#{inspect(args)}).")
    {:noreply, state}
  end

  def handle_call({:add_client, pid}, _from, state) do
    {:reply, :ok, update_in(state[:clients], &MapSet.put(&1, pid))}
  end

  def handle_call({:remove_client, pid}, _from, state) do
    {:reply, :ok, update_in(state[:clients], &MapSet.delete(&1, pid))}
  end

  #############################################################################
  ### Helpers
  #############################################################################

  def send_to_clients(clients, msg) do
    Enum.each(clients, fn pid -> send(pid, msg) end)
  end
end
