defmodule Lyskom.Server do
  use GenServer

  require Logger

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def incoming(msg) do
    Logger.info("Got a message: #{inspect msg}")
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{next_call_id: 1, pending: %{} }}
  end

  ## Handle calls
  # FIXME: Temporary thing to try out the wait-until-later method.
  def handle_call({:login, name, password}, from, state = %{next_call_id: next_id}) do
    Logger.info("#{next_id} 63 #{name} #{password}\n")
    state = put_in state.next_call_id, next_id + 1
    state = put_in state.pending[next_id], {:login, from}
    Process.send_after(@me, :reply, 10000)
    {:noreply, state}
  end

  ## Handle random messages
  # FIXME: Other half of temporary thing
  def handle_info(:reply, state) do
    Logger.info "Got message :reply"
    for {call, from} <- Map.values(state.pending) do
      GenServer.reply(from, call)
    end
    {:noreply, %{ state | pending: %{}}}
  end

end
