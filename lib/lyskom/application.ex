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
    children = [
      {Registry, keys: :unique, name: Lyskom.Registry},
      %{
        id: Lyskom.DynamicSupervisor,
        start:
          {DynamicSupervisor, :start_link,
           [[strategy: :one_for_one, name: Lyskom.DynamicSupervisor]]},
        type: :supervisor
      }
    ]

    opts = [strategy: :one_for_one, name: Lyskom.TopSupervisor]
    Supervisor.start_link(children, opts)
  end
end
