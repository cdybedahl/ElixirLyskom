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

  #############################################################################
  ### Callbacks
  #############################################################################

  def init(:no_args) do
    {:ok, %{}}
  end

  def handle_cast({:async_new_text_old, [text_no | text_stat_old]}, state) do
    stat = Lyskom.ProtA.Type.TextStat.old(text_stat_old)
    Logger.info("New text #{text_no}: #{inspect(stat)}")
    {:noreply, state}
  end

  def handle_cast({:async_sync_db, []}, state) do
    Logger.info("Database synchronizing.")
    {:noreply, state}
  end

  def handle_cast({type, args}, state) do
    Logger.info("Async #{inspect(type)} (#{inspect(args)}).")
    {:noreply, state}
  end
end
