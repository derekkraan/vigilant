defmodule ProcessMonitor do
  @moduledoc """
  ProcessMonitor offers tools to help monitor processes.
  """

  @doc """
  Monitors the process identified by `pid` and ensures that it does not exceed `memory_limit_mb`.
  """
  def limit_memory_mb(pid, memory_limit_mb) do
    {:ok, _child} =
      DynamicSupervisor.start_child(
        ProcessMonitor.MonitorSupervisor,
        %{
          id: "ProcessMonitor.MonitorMemory.#{inspect(pid)}",
          start: {GenServer, :start_link, [ProcessMonitor.MonitorMemory, {pid, memory_limit_mb}]}
        }
      )
  end

  @doc """
  Kills the calling process if `fun.()` does not complete within the timeout.
  """
  def enforce_timeout(fun, timeout \\ 5_000, after_timeout \\ fn -> nil end) do
    id = "ProcessMonitor.MonitorTimeout.#{inspect(self())}"

    {:ok, child} =
      DynamicSupervisor.start_child(
        ProcessMonitor.MonitorSupervisor,
        %{
          id: id,
          start:
            {GenServer, :start_link,
             [ProcessMonitor.MonitorTimeout, {self(), timeout, after_timeout}]}
        }
      )

    try do
      fun.()
    after
      DynamicSupervisor.terminate_child(ProcessMonitor.MonitorSupervisor, child)
    end
  end
end
