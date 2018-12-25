defmodule Lyskom.AsyncHandler do
  use GenServer
  require Logger

  alias Lyskom.ProtA.Type
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
       {:async_new_text_old, to_integer(text_no), Type.TextStat.old(text_stat_old)}
     )}
  end

  def handle_cast({:async_new_text, [text_no | text_stat]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_new_text, to_integer(text_no), Type.TextStat.new(text_stat)}
     )}
  end

  def handle_cast({:async_deleted_text, [text_no | text_stat]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_deleted_text, to_integer(text_no), Type.TextStat.new(text_stat)}
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
       {:async_i_am_on, to_integer(pers_no), to_integer(conf_no), to_integer(session_no),
        Type.decode_string(what), Type.decode_string(username)}
     )}
  end

  def handle_cast({:async_text_aux_changed, [text_no, deleted, added]}, state) do
    {
      :noreply,
      send_to_clients(
        state,
        {
          :async_text_aux_changed,
          to_integer(text_no),
          Enum.map(deleted, &Lyskom.ProtA.Type.AuxItem.new/1),
          Enum.map(added, &Lyskom.ProtA.Type.AuxItem.new/1)
        }
      )
    }
  end

  def handle_cast({:async_new_name, [conf_no, old_name, new_name]}, state) do
    {:noreply,
     send_to_clients(
       state,
       {:async_new_name, to_integer(conf_no), Type.decode_string(old_name),
        Type.decode_string(new_name)}
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
