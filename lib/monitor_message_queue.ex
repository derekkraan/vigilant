defmodule Vigilant.MonitorMessageQueue do
  use GenServer
  require Logger

  @moduledoc """
  Vigilant monitors your processes and kills them when their message queue
  grows above set limit.
  """

  @tick_interval 500

  def init({pid, message_queue_size}) do
    Logger.debug("monitoring #{inspect(pid)}, ensuring its message queue size stays under #{message_queue_size}")
    schedule_next_check()
    Process.monitor(pid)
    {:ok, {pid, message_queue_size}}
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, {pid, message_queue_size}) do
    Logger.debug(fn -> "Process #{inspect(pid)} is DOWN, stopping monitor" end)
    {:stop, :normal, {pid, message_queue_size}}
  end

  def handle_info(:tick, {pid, message_queue_size}) do
    {:message_queue_len, size} = Process.info(pid, :message_queue_len)

    if(size > message_queue_size) do
      Logger.debug(fn ->
        "killing process #{inspect(pid)} because it's message queue size (#{size})
        is greater than #{message_queue_size}."
      end)

      Process.exit(pid, :kill)

      {:stop, :normal, nil}
    else
      Logger.debug(fn ->
        "not killing process #{inspect(pid)} because it's message queue size (#{size})
        isn't greater than #{message_queue_size}."
      end)

      schedule_next_check()
      {:noreply, {pid, message_queue_size}}
    end
  end

  defp schedule_next_check(), do: Process.send_after(self(), :tick, @tick_interval)
end
