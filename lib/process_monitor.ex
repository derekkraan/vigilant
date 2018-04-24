defmodule ProcessMonitor do
  @moduledoc """
  ProcessMonitor offers tools to help monitor processes.
  """

  @doc """
  Monitors the process identified by `pid` and ensures that it does not exceed `memory_limit_mb`.
  """
  def limit_memory_mb(pid \\ self(), memory_limit_mb) do
    GenServer.start_link(ProcessMonitor.MonitorMemory, {pid, memory_limit_mb})
  end
end
