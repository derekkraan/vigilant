defmodule ProcessMonitor.MonitorTimeout do
  use GenServer
  require Logger

  @moduledoc """
  MonitorTimeout kills a process if a timeout is reached.
  """

  def init({pid, timeout, after_timeout}) do
    Logger.debug("monitoring #{inspect(pid)}, killing it if #{timeout} is reached.")
    Process.send_after(self(), :timeout, timeout)
    {:ok, {pid, after_timeout}}
  end

  def handle_info(:timeout, {pid, after_timeout}) do
    Process.exit(pid, :kill)
    after_timeout.()
    {:stop, :normal, pid}
  end

  def handle_call(:cancel_timeout, _from, _state) do
    {:stop, :normal, :ok, nil}
  end
end
