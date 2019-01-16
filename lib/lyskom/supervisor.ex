defmodule Lyskom.Supervisor do
  use Supervisor, restart: :transient
  require Logger

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:supervisor, ref}}}
  end

  def start_link([name, host, port]) do
    Supervisor.start_link(__MODULE__, [name, host, port], name: _name(name))
  end

  def init([name, host, port]) do
    sub_children = [
      {Lyskom.Server, name},
      {Lyskom.Parser, name},
      {Lyskom.ProtA.Tokenize, name},
      {Lyskom.Socket, [name, host, port]}
    ]

    sub_opts = [strategy: :one_for_all]

    children = [
      {Lyskom.AsyncHandler, name},
      {Lyskom.Cache, name},
      %{
        id: Lyskom.SubSupervisor,
        start: {Supervisor, :start_link, [sub_children, sub_opts]},
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
