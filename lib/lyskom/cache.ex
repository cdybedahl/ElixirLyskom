defmodule Lyskom.Cache do
  use GenServer

  @me __MODULE__
  @remember_seconds 300

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def put(type, key, data) do
    GenServer.call(@me, {:put, type, key, data})
  end

  def get(type, key) do
    GenServer.call(@me, {:get, type, key})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{}}
  end

  def handle_call({:put, type, key, data}, _from, state) do
    {:reply, :ok, put_in(state[{type, key}], {data, DateTime.utc_now()})}
  end

  def handle_call({:get, type, key}, _from, state) do
    data = state[{type, key}]

    if data != nil and DateTime.diff(DateTime.utc_now(), elem(data, 1)) > @remember_seconds do
      {:reply, nil, Map.delete(state, {type, key})}
    else
      {:reply, elem(data, 0), state}
    end
  end
end
