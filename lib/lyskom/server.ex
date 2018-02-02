defmodule Lyskom.Server do
  use GenServer

  require Logger
  import Lyskom.ProtA.Type
  alias Lyskom.ProtA.Type
  import Lyskom.ProtA.Error

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def incoming(msg) do
    # Logger.debug("Got a message: #{inspect(msg)}")
    GenServer.cast(@me, {:incoming, msg})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{next_call_id: 1, pending: %{}}}
  end

  def terminate(_reason, state) do
    Enum.each(state.pending, fn {_id, {_call, from, _data}} -> GenServer.reply(from, :retry) end)
  end

  #############################################################################
  ## Handle calls
  #############################################################################

  def handle_call(
        {:login, id_number, password, invisible},
        from,
        state
      ) do
    prot_a_call(:login, 62, from, [id_number, hollerith(password), boolean(invisible)], state)
  end

  def handle_call({:logout}, from, state) do
    prot_a_call(:logout, 1, from, [], state)
  end

  def handle_call({:lookup_z_name, name, want_pers, want_confs}, from, state) do
    prot_a_call(
      :lookup_z_name,
      76,
      from,
      [hollerith(name), boolean(want_pers), boolean(want_confs)],
      state
    )
  end

  def handle_call({:who_is_on, want_visible, want_invisible, active_last}, from, state) do
    prot_a_call(
      :who_is_on,
      83,
      from,
      [boolean(want_visible), boolean(want_invisible), active_last],
      state
    )
  end

  def handle_call({:get_conf_stat, conf_no}, from, state) do
    case Lyskom.Cache.get(:get_conf_stat, conf_no) do
      nil ->
        prot_a_call(:get_conf_stat, 91, from, [conf_no], state)

      data ->
        {:reply, data, state}
    end
  end

  def handle_call({:query_async}, from, state) do
    prot_a_call(:query_async, 81, from, [], state)
  end

  def handle_call({:get_text_stat, text_no}, from, state) do
    prot_a_call(:get_text_stat, 90, from, [text_no], state)
  end

  def handle_call({:get_text, text_no, start_char, end_char}, from, state) do
    prot_a_call(:get_text, 25, from, [text_no, start_char, end_char], state)
  end

  def handle_call({:get_unread_confs, pers_no}, from, state) do
    prot_a_call(:get_unread_confs, 52, from, [pers_no], state)
  end

  # Helper functions ##########################################################
  def add_call_to_state(state = %{next_call_id: next_id}, call_args) do
    state = put_in(state.next_call_id, next_id + 1)
    put_in(state.pending[next_id], call_args)
  end

  def prot_a_call(call_type, call_no, from, args, state = %{next_call_id: next_id}) do
    [next_id, call_no | args]
    |> Enum.join(" ")
    |> Kernel.<>("\n")
    |> Lyskom.Socket.send()

    {:noreply, add_call_to_state(state, {call_type, from, args})}
  end

  #############################################################################
  ## Handle casts
  #############################################################################

  def handle_cast({:incoming, [:async, _argcount, type | args]}, state) do
    Lyskom.AsyncHandler.handle(type, args)

    {:noreply, state}
  end

  def handle_cast({:incoming, [type, id | args]}, state) do
    id = List.to_integer(id)
    {call, from, call_args} = Map.fetch!(state.pending, id)
    state = put_in(state.pending, Map.delete(state.pending, id))
    process_response(call, type, from, args, call_args)
    {:noreply, state}
  end

  #############################################################################
  ## Handle random messages
  #############################################################################

  def handle_info(something, state) do
    Logger.info("Got message: #{inspect(something)}")
    {:noreply, state}
  end

  #############################################################################
  ## Processing responses. Maybe should be in a separate module.
  #############################################################################

  def process_response(:login, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def process_response(:login, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def process_response(:logout, :success, from, [], _call_args) do
    GenServer.reply(from, :ok)
  end

  def process_response(:lookup_z_name, :success, from, [infolist], _call_args) do
    GenServer.reply(from, Enum.map(infolist, fn c -> Type.ConfZInfo.new(c) end))
  end

  def process_response(:who_is_on, :success, from, [sessions], _call_args) do
    GenServer.reply(from, Enum.map(sessions, fn c -> Type.DynamicSessionInfo.new(c) end))
  end

  def process_response(:get_conf_stat, :success, from, conflist, [conf_no]) do
    GenServer.reply(
      from,
      Lyskom.Cache.put(:get_conf_stat, conf_no, Type.Conference.new(conflist))
    )
  end

  def process_response(:get_conf_stat, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def process_response(:query_async, :success, from, [asynclist], _call_args) do
    GenServer.reply(from, Enum.map(asynclist, fn [n] -> List.to_integer(n) end))
  end

  def process_response(:get_text_stat, :success, from, text_stat, _call_args) do
    GenServer.reply(from, Type.TextStat.new(text_stat))
  end

  def process_response(:get_text_stat, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def process_response(:get_text, :success, from, [text], _call_args) do
    GenServer.reply(from, text)
  end

  def process_response(:get_text, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def process_response(:get_unread_confs, :success, from, [conf_no_list], _call_args) do
    GenServer.reply(from, Enum.map(conf_no_list, fn [n] -> List.to_integer(n) end))
  end

  def process_response(:get_unread_confs, :failure, from, [code | args], _call_args) do
    GenServer.reply(from, {:error, error_code(code), args})
  end
end
