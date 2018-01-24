defmodule Lyskom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

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
