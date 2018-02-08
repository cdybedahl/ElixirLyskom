defmodule Lyskom.AsyncHandler do
  use GenServer
  require Logger

  import Lyskom.ProtA.Async
  import List, only: [to_integer: 1]

  @me __MODULE__

  #############################################################################
  ### API
  #############################################################################

  def start_link(name_base) do
    GenServer.start_link(@me, name_base, name: _name(name_base))
  end

  def handle(type, args, name_base) do
    GenServer.cast(_name(name_base), {async(type), args})
  end

  def add_client(pid, name_base) do
    GenServer.call(_name(name_base), {:add_client, pid})
  end

  def remove_client(pid, name_base) do
    GenServer.call(_name(name_base), {:remove_client, pid})
  end

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:async_handler, ref}}}
  end

  #############################################################################
  ### Callbacks
  #############################################################################

  def init(name_base) do
    {:ok, %{name_base: name_base, clients: MapSet.new()}}
  end

  #############################################################################
  def handle_cast({:async_new_text_old, [text_no | text_stat_old]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_new_text_old, to_integer(text_no), Lyskom.ProtA.Type.TextStat.old(text_stat_old)}
     )}
  end

  def handle_cast({:async_new_text, [text_no | text_stat]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_new_text, to_integer(text_no), Lyskom.ProtA.Type.TextStat.new(text_stat)}
     )}
  end

  def handle_cast({:async_deleted_text, [text_no | text_stat]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_deleted_text, to_integer(text_no), Lyskom.ProtA.Type.TextStat.new(text_stat)}
     )}
  end

  def handle_cast({:async_sync_db, []}, state) do
    {:noreply, send_to_clients(state, {:async_sync_db})}
  end

  def handle_cast({:async_login, [pers_no, session_no]}, state) do
    {:noreply,
     send_to_clients(state, {:async_login, to_integer(pers_no), to_integer(session_no)})}
  end

  def handle_cast({:async_logout, [pers_no, session_no]}, state) do
    {:noreply,
     send_to_clients(state, {:async_logout, to_integer(pers_no), to_integer(session_no)})}
  end

  def handle_cast({:async_i_am_on, [pers_no, conf_no, session_no, what, username]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_i_am_on, to_integer(pers_no), to_integer(conf_no), to_integer(session_no), what,
        username}
     )}
  end

  def handle_cast({type, args}, state) do
    Logger.info("AsyncHandler unimplemented: #{inspect(type)} (#{inspect(args)}).")
    {:noreply, send_to_clients(state, {type, args})}
  end

  #############################################################################
  def handle_call({:add_client, pid}, _from, state) do
    {:reply, :ok, update_in(state[:clients], &MapSet.put(&1, pid))}
  end

  def handle_call({:remove_client, pid}, _from, state) do
    {:reply, :ok, update_in(state[:clients], &MapSet.delete(&1, pid))}
  end

  #############################################################################
  ### Helpers
  #############################################################################

  def send_to_clients(state = %{clients: clients}, msg) do
    :ok = Enum.each(clients, fn pid -> send(pid, msg) end)
    state
  end
end
