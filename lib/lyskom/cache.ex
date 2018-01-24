defmodule Lyskom.Cache do
  use GenServer
  require Logger

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
    {:reply, data, put_in(state[{type, key}], {data, DateTime.utc_now()})}
  end

  def handle_call({:get, type, key}, _from, state) do
    if Map.has_key?(state, {type, key}) do
      {data, timestamp} = state[{type, key}]

      if DateTime.diff(DateTime.utc_now(), timestamp) > @remember_seconds do
        {:reply, nil, Map.delete(state, {type, key})}
      else
        {:reply, data, state}
      end
    else
      {:reply, nil, state}
    end
  end
end
