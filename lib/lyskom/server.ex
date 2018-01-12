defmodule Lyskom.Server do
  use GenServer

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{}}
  end

end
