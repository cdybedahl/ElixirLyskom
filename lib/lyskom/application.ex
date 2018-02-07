defmodule Lyskom.Application do
  use Application
  @moduledoc """
   +--------------+     +-------------------+
   |   Registry   | <-- |   TopSupervisor   |
   +--------------+     +-------------------+
                          |
                          |
                          v
                        +-------------------+
                        | DynamicSupervisor |
                        +-------------------+
                          |
                          |
                          v
   +--------------+     +-------------------+     +--------+
   | AsyncHandler | <-- | LyskomSupervisor  | --> | Cache  |
   +--------------+     +-------------------+     +--------+
                          |
                          |
                          v
   +--------------+     +----------------------------------+     +-----------+
   |    Socket    | <-- |       LyskomSubSupervisor        | --> | Tokenizer |
   +--------------+     +----------------------------------+     +-----------+
                          |                         |
                          |                         |
                          v                         v
                        +-------------------+     +--------+
                        |      Parser       |     | Server |
                        +-------------------+     +--------+

  """

  def start(_type, _args) do
    sub_children = [
      Lyskom.Server,
      Lyskom.Parser,
      Lyskom.ProtA.Tokenize,
      Lyskom.Socket
    ]

    sub_opts = [strategy: :one_for_all, name: Lyskom.SubSupervisor]

    children = [
      # Starts a worker by calling: Lyskom.Worker.start_link(arg)
      # {Lyskom.Worker, arg},
      {Registry, keys: :unique, name: Lyskom.Registry},
      Lyskom.AsyncHandler,
      Lyskom.Cache,
      %{
        id: Lyskom.SubSupervisor,
        start: {Supervisor, :start_link, [sub_children, sub_opts]},
        type: :supervisor
      }
    ]

    opts = [strategy: :one_for_one, name: Lyskom.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
