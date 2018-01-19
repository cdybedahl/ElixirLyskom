defmodule Lyskom.Cache do
  use GenServer

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def store_name(id,name) do
    GenServer.call(@me, {:store, id, name})
  end

  def get_name(id) do
    GenServer.call(@me, {:get, id})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{}}
  end

  def handle_call({:store, id, name}, _from, state) do
    {:reply, :ok, put_in(state[id], {name, DateTime.utc_now})}
  end

  def handle_call({:get, id}, _from, state) do
    {name, timestamp} = state[id]
    if DateTime.diff(DateTime.utc_now, timestamp) > 3600 do
      {:reply, nil, Map.delete(state, id)}
    else
      {:reply, name, state}
    end
  end
end
