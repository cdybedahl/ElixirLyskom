defmodule Lyskom.Server.Process do
  import Lyskom.ProtA.Error
  alias Lyskom.ProtA.Type

  def response(:login, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:login, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def response(:logout, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def response(:lookup_z_name, :success, from, [infolist], _call_args) do
    GenServer.reply(from, Enum.map(infolist, fn c -> Type.ConfZInfo.new(c) end))
  end

  def response(:who_is_on, :success, from, [sessions], _call_args) do
    GenServer.reply(from, Enum.map(sessions, fn c -> Type.DynamicSessionInfo.new(c) end))
  end

  def response(:get_conf_stat, :success, from, conflist, [conf_no]) do
    GenServer.reply(
      from,
      Lyskom.Cache.put(:get_conf_stat, conf_no, Type.Conference.new(conflist))
    )
  end

  def response(:get_conf_stat, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def response(:query_async, :success, from, [asynclist], _call_args) do
    GenServer.reply(from, Enum.map(asynclist, fn [n] -> List.to_integer(n) end))
  end

  def response(:get_text_stat, :success, from, text_stat, _call_args) do
    GenServer.reply(from, Type.TextStat.new(text_stat))
  end

  def response(:get_text_stat, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def response(:get_text, :success, from, [text], _call_args) do
    GenServer.reply(from, text)
  end

  def response(:get_text, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def response(:get_unread_confs, :success, from, [conf_no_list], _call_args) do
    GenServer.reply(from, Enum.map(conf_no_list, fn [n] -> List.to_integer(n) end))
  end

  def response(:get_unread_confs, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end
end
