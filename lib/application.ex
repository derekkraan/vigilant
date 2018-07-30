defmodule ProcessMonitor.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, [strategy: :one_for_one, name: ProcessMonitor.MonitorSupervisor]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ProcessMonitor.Supervisor)
  end
end
