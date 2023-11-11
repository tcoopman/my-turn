defmodule MyTurn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {MyTurn.Queue, []},
      # Start the Telemetry supervisor
      MyTurnWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MyTurn.PubSub},
      # Start Finch
      {Finch, name: MyTurn.Finch},
      # Start the Endpoint (http/https)
      MyTurnWeb.Endpoint
      # Start a worker by calling: MyTurn.Worker.start_link(arg)
      # {MyTurn.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyTurn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MyTurnWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
