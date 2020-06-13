defmodule Lyskom.Async do
  require Logger
  import Lyskom.Constants
  alias Lyskom.Type
  import List, only: [to_integer: 1]

  def handle(type, args, _state) do
    Registry.dispatch(Lyskom.AsyncSubscribers, self(), fn entries ->
      for {pid, set} <- entries do
        if MapSet.member?(set, type) do
          send(pid, parse_async({async(type), args}))
        end
      end
    end)
  end

  def parse_async({:async_new_text_old, [text_no | text_stat_old]}) do
    {:async_new_text_old, to_integer(text_no), Type.TextStat.old(text_stat_old)}
  end

  def parse_async({:async_new_text, [text_no | text_stat]}) do
    {:async_new_text, to_integer(text_no), Type.TextStat.new(text_stat)}
  end

  def parse_async({:async_deleted_text, [text_no | text_stat]}) do
    {:async_deleted_text, to_integer(text_no), Type.TextStat.new(text_stat)}
  end

  def parse_async({:async_sync_db, []}) do
    {:async_sync_db}
  end

  def parse_async({:async_login, [pers_no, session_no]}) do
    {:async_login, to_integer(pers_no), to_integer(session_no)}
  end

  def parse_async({:async_logout, [pers_no, session_no]}) do
    {:async_logout, to_integer(pers_no), to_integer(session_no)}
  end

  def parse_async({:async_i_am_on, [pers_no, conf_no, session_no, what, username]}) do
    {:async_i_am_on, to_integer(pers_no), to_integer(conf_no), to_integer(session_no),
     Type.decode_string(what), Type.decode_string(username)}
  end

  def parse_async({:async_text_aux_changed, [text_no, deleted, added]}) do
    {
      :async_text_aux_changed,
      to_integer(text_no),
      Enum.map(deleted, &Type.AuxItem.new/1),
      Enum.map(added, &Type.AuxItem.new/1)
    }
  end

  def parse_async({:async_new_name, [conf_no, old_name, new_name]}) do
    {:async_new_name, to_integer(conf_no), Type.decode_string(old_name),
     Type.decode_string(new_name)}
  end

  def parse_async({:async_send_message, [to, from, msg]}) do
    {:async_send_message, to_integer(to), to_integer(from), Type.decode_string(msg)}
  end
end
