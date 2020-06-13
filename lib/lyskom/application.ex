defmodule Lyskom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Lyskom.Registry},
      %{
        id: Lyskom.Super,
        start: {DynamicSupervisor, :start_link, [[strategy: :one_for_one, name: Lyskom.Super]]},
        type: :supervisor
      },
      {Registry, keys: :duplicate, name: Lyskom.AsyncSubscribers}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lyskom.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
