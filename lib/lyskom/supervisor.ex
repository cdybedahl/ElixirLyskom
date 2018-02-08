defmodule Lyskom.Supervisor do
  use Supervisor
  require Logger

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:supervisor, ref}}}
  end

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: _name(arg))
  end

  def init(arg) do
    sub_children = [
      {Lyskom.Server, arg},
      Lyskom.Parser,
      Lyskom.ProtA.Tokenize,
      Lyskom.Socket
    ]

    sub_opts = [strategy: :one_for_all, name: Lyskom.SubSupervisor]

    children = [
      Lyskom.AsyncHandler,
      Lyskom.Cache,
      %{
        id: Lyskom.SubSupervisor,
        start: {Supervisor, :start_link, [sub_children, sub_opts]},
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
