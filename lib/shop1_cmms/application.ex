defmodule Shop1Cmms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Shop1CmmsWeb.Telemetry,
      Shop1Cmms.Repo,
      {DNSCluster, query: Application.get_env(:shop1_cmms, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Shop1Cmms.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Shop1Cmms.Finch},
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:shop1_cmms, Oban)},
      # Start a worker by calling: Shop1Cmms.Worker.start_link(arg)
      # {Shop1Cmms.Worker, arg},
      # Start to serve requests, typically the last entry
      Shop1CmmsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shop1Cmms.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Shop1CmmsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
