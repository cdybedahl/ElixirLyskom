defmodule Lyskom.Responses do
  require Logger
  import List, only: [to_integer: 1]
  import Lyskom.Constants

  alias Lyskom.Type

  def handle([:async, _argcount, type | args], state) do
    Lyskom.Async.handle(to_integer(type), args, state)
    state
  end

  def handle([type, id | args], state) do
    id = to_integer(id)

    case Map.fetch(state.outstanding_calls, id) do
      {:ok, {call, from, call_args}} ->
        response(call, type, from, args, call_args)
        Map.update!(state, :outstanding_calls, fn m -> Map.delete(m, id) end)

      :error ->
        Logger.debug("Unexpected response: #{type} #{id} #{inspect(args)}")
        state
    end
  end

  def response(:login, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:logout, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:get_info, :success, from, info, _call_args) do
    GenServer.reply(from, Type.Info.new(info))
  end

  def response(:get_time, :success, from, time, _call_args) do
    GenServer.reply(from, Type.Time.new(time))
  end

  def response(:lookup_z_name, :success, from, [infolist], _call_args) do
    GenServer.reply(from, Enum.map(infolist, fn c -> Type.ConfZInfo.new(c) end))
  end

  def response(:who_is_on, :success, from, [sessions], _call_args) do
    GenServer.reply(from, Enum.map(sessions, fn c -> Type.DynamicSessionInfo.new(c) end))
  end

  def response(:get_conf_stat, :success, from, conflist, _call_args) do
    GenServer.reply(from, Type.Conference.new(conflist))
  end

  def response(:query_async, :success, from, [asynclist], _call_args) do
    GenServer.reply(from, Enum.map(asynclist, fn [n] -> List.to_integer(n) end))
  end

  def response(:accept_async, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:get_text_stat, :success, from, text_stat, _call_args) do
    GenServer.reply(from, Type.TextStat.new(text_stat))
  end

  def response(:get_text, :success, from, [text], _call_args) do
    GenServer.reply(from, text)
  end

  def response(:get_unread_confs, :success, from, [conf_no_list], _call_args) do
    GenServer.reply(from, Enum.map(conf_no_list, fn [n] -> List.to_integer(n) end))
  end

  def response(:query_read_texts, :success, from, list, _call_args) do
    GenServer.reply(from, Type.Membership.new(list))
  end

  def response(:local_to_global, :success, from, list, _call_args) do
    GenServer.reply(from, Type.TextMapping.new(list))
  end

  def response(:find_next_text_no, :success, from, [text_no], _call_args) do
    GenServer.reply(from, List.to_integer(text_no))
  end

  def response(:get_person_stat, :success, from, list, _call_args) do
    GenServer.reply(from, Type.Person.new(list))
  end

  def response(:mark_as_read, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:send_message, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:create_text, :success, from, [text_no], _call_args) do
    GenServer.reply(from, List.to_integer(text_no))
  end

  # Generic failure response handler
  def response(_call_type, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end
end
