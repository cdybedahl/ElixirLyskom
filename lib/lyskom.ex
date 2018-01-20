defmodule Lyskom do
  @server Lyskom.Server

  def login(id_number, password, invisible \\ false) do
    GenServer.call(@server, {:login, id_number, password, invisible}, :infinity)
  end

  def logout do
    GenServer.call(@server, {:logout}, :infinity)
  end

  def lookup_z_name(name, want_pers \\ true, want_confs \\ true) do
    GenServer.call(@server, {:lookup_z_name, name, want_pers, want_confs}, :infinity)
  end

  def who_is_on(want_visible \\ true, want_invisible \\ false, active_last \\ 1800) do
    GenServer.call(@server, {:who_is_on, want_visible, want_invisible, active_last}, :infinity)
  end
end
