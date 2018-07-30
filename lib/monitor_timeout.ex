defmodule Vigilant.MonitorTimeout do
  use GenServer
  require Logger

  @moduledoc """
  MonitorTimeout kills a process if a timeout is reached.
  """

  def init({pid, timeout, after_timeout}) do
    Logger.debug("monitoring #{inspect(pid)}, killing it if #{timeout} is reached.")
    Process.monitor(pid)
    Process.send_after(self(), :timeout, timeout)
    {:ok, {pid, after_timeout}}
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, state),
    do: {:stop, :normal, state}

  def handle_info(:timeout, {pid, after_timeout}) do
    Process.exit(pid, :kill)
    after_timeout.()
    {:stop, :normal, pid}
  end
end
