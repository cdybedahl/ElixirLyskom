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
    prot_a_call(:get_conf_stat, 91, from, [conf_no], state)
  end

  # Helper functions
  def add_call_to_state(state = %{next_call_id: next_id}, data) do
    state = put_in(state.next_call_id, next_id + 1)
    put_in(state.pending[next_id], data)
  end

  def prot_a_call(call_type, call_no, from, args, state = %{next_call_id: next_id}) do
    [next_id, call_no | args]
    |> Enum.join(" ")
    |> Kernel.<>("\n")
    |> Lyskom.Socket.send()

    {:noreply, add_call_to_state(state, {call_type, from})}
  end

  #############################################################################
  ## Handle casts
  #############################################################################

  def handle_cast({:incoming, [:async, argcount, type | args]}, state) do
    Logger.info("Got async message type #{type} with #{argcount} arguments (#{inspect(args)}).")
    {:noreply, state}
  end

  def handle_cast({:incoming, [type, id | args]}, state) do
    id = List.to_integer(id)
    {call, from} = Map.fetch!(state.pending, id)
    state = put_in(state.pending, Map.delete(state.pending, id))
    process_response(call, type, from, args)
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

  def process_response(:login, :success, from, []) do
    GenServer.reply(from, :ok)
  end

  def process_response(:login, :failure, from, [code | args]) do
    GenServer.reply(from, {:error, error_code(code), args})
  end

  def process_response(:logout, :success, from, []) do
    GenServer.reply(from, :ok)
  end

  def process_response(:lookup_z_name, :success, from, [infolist]) do
    GenServer.reply(from, Enum.map(infolist, fn c -> Type.ConfZInfo.new(c) end))
  end

  def process_response(:who_is_on, :success, from, [sessions]) do
    GenServer.reply(from, Enum.map(sessions, fn c -> Type.DynamicSessionInfo.new(c) end))
  end

  def process_response(:get_conf_stat, :success, from, conflist) do
    GenServer.reply(from, Type.Conference.new(conflist))
  end

  def process_response(:get_conf_stat, :failure, from, [code | args]) do
    GenServer.reply(from, {:error, error_code(code), args})
  end
end
