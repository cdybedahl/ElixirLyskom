defmodule Lyskom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Lyskom.Worker.start_link(arg)
      # {Lyskom.Worker, arg},
      Lyskom.Cache,
      Lyskom.Server,
      Lyskom.Parser,
      Lyskom.Socket
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: Lyskom.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
