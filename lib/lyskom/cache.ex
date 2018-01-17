defmodule Lyskom.Cache do
  use GenServer

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{}}
  end
end
