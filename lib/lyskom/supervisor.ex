defmodule Lyskom.Supervisor do
  use Supervisor
  require Logger

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:supervisor, ref}}}
  end

  def start_link(arg) do
    Logger.info("Supervisor start argument: #{inspect(arg)}")
    Supervisor.start_link(__MODULE__, arg, name: _name(arg))
  end

  def init(arg) do
    sub_children = [
      {Lyskom.Server, arg},
      {Lyskom.Parser, arg},
      {Lyskom.ProtA.Tokenize, arg},
      {Lyskom.Socket, arg}
    ]

    sub_opts = [strategy: :one_for_all]

    children = [
      {Lyskom.AsyncHandler, arg},
      {Lyskom.Cache, arg},
      %{
        id: Lyskom.SubSupervisor,
        start: {Supervisor, :start_link, [sub_children, sub_opts]},
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
