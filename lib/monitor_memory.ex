defmodule Vigilant.MonitorMemory do
  use GenServer
  require Logger

  @megabyte :math.pow(2, 20)

  @moduledoc """
  Vigilant monitors your processes and kills them when they consume too much memory or too much CPU.
  """

  @tick_interval 500

  def init({pid, memory_limit_mb}) do
    Logger.debug("monitoring #{inspect(pid)}, ensuring it stays under #{memory_limit_mb}Mb")
    schedule_next_check()
    Process.monitor(pid)
    {:ok, {pid, memory_limit_mb * @megabyte}}
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, {pid, memory_limit_bytes}) do
    Logger.debug(fn -> "Process #{inspect(pid)} is DOWN, stopping monitor" end)
    {:stop, :normal, {pid, memory_limit_bytes}}
  end

  def handle_info(:tick, {pid, memory_limit_bytes}) do
    {:memory, memory_bytes} = Process.info(pid, :memory)

    if(memory_bytes > memory_limit_bytes) do
      Logger.debug(fn ->
        "killing process #{inspect(pid)} because it's memory usage (#{
          round(memory_bytes / @megabyte)
        }Mb) is greater than #{round(memory_limit_bytes / @megabyte)}Mb."
      end)

      Process.exit(pid, :kill)

      {:stop, :normal, nil}
    else
      Logger.debug(fn ->
        "not killing process #{inspect(pid)} because it's memory usage (#{
          round(memory_bytes / @megabyte)
        }Mb) isn't greater than #{round(memory_limit_bytes / @megabyte)}Mb."
      end)

      schedule_next_check()
      {:noreply, {pid, memory_limit_bytes}}
    end
  end

  defp schedule_next_check(), do: Process.send_after(self(), :tick, @tick_interval)
end
