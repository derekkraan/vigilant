defmodule ProcessMonitor do
  @moduledoc """
  ProcessMonitor offers tools to help monitor processes.
  """

  @doc """
  Monitors the process identified by `pid` and ensures that it does not exceed `memory_limit_mb`.
  """
  def limit_memory_mb(pid, memory_limit_mb) do
    GenServer.start_link(ProcessMonitor.MonitorMemory, {pid, memory_limit_mb})
  end

  @doc """
  Kills the calling process if `fun.()` does not complete within the timeout.
  """
  def enforce_timeout(fun, timeout \\ 5_000, after_timeout \\ fn -> nil end) do
    {:ok, monitor_timeout} =
      GenServer.start_link(ProcessMonitor.MonitorTimeout, {self(), timeout, after_timeout})

    out =
      try do
        fun.()
      after
        GenServer.call(monitor_timeout, :cancel_timeout)
      end

    out
  end
end
