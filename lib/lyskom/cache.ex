defmodule Lyskom.Cache do
  use GenServer

  @me __MODULE__
  @remember_seconds 60

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def store_name(id, name) do
    GenServer.call(@me, {:store, id, name})
  end

  def get_name(id) do
    GenServer.call(@me, {:get, id})
  end

  ### Callbacks

  def init(:no_args) do
    {
      :ok,
      %{
        names: %{}
      }
    }
  end

  def handle_call({:store, id, name}, _from, state) do
    {:reply, :ok, put_in(state.names[id], {name, DateTime.utc_now()})}
  end

  def handle_call({:get, id}, _from, state = %{names: db}) do
    {name, timestamp} = db[id]

    if DateTime.diff(DateTime.utc_now(), timestamp) > @remember_seconds do
      {:reply, nil, update_in(state.names, fn n -> Map.delete(n, id) end)}
    else
      {:reply, name, state}
    end
  end
end
