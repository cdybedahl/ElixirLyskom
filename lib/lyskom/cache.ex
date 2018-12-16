defmodule Lyskom.Cache do
  use GenServer
  require Logger

  @me __MODULE__
  @remember_seconds 300

  ### API

  def start_link(name_base) do
    GenServer.start_link(@me, name_base, name: _name(name_base))
  end

  def put(type, key, data, name_base) do
    GenServer.call(_name(name_base), {:put, type, key, data})
  end

  def get(type, key, name_base) do
    GenServer.call(_name(name_base), {:get, type, key})
  end

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:cache, ref}}}
  end

  def logged_in?(name_base, id, pass, invis) do
    GenServer.cast(_name(name_base), {:set_login, [name_base, id, pass, invis]})
  end

  def logged_in?(name_base) do
    GenServer.call(_name(name_base), {:get_login})
  end

  ### Callbacks

  def init(name_base) do
    {:ok, %{name_base: name_base, login_args: nil}}
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

  def handle_call({:get_login}, _from, state) do
    {:reply, state.login_args, state}
  end

  def handle_cast({:set_login, args}, state) do
    {:noreply, Map.put(state, :login_args, args)}
  end
end
