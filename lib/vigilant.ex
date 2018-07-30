defmodule Vigilant do
  @moduledoc """
  Vigilant offers tools to help monitor processes.
  """

  @doc """
  Monitors the process identified by `pid` and ensures that it does not exceed `memory_limit_mb`.
  """
  @spec limit_memory(pid :: pid(), memory_limit_mb :: integer()) :: :ok
  def limit_memory(pid \\ self(), memory_limit_mb) do
    {:ok, _child} =
      DynamicSupervisor.start_child(
        Vigilant.MonitorSupervisor,
        %{
          id: "Vigilant.MonitorMemory.#{inspect(pid)}",
          start: {GenServer, :start_link, [Vigilant.MonitorMemory, {pid, memory_limit_mb}]},
          restart: :transient
        }
      )

    :ok
  end

  @doc """
  Kills the calling process if `fun.()` does not complete within the timeout. Returns the result of calling `fun.()`.
  """
  @spec enforce_timeout(
          fun :: (() -> response :: any()),
          timeout :: integer(),
          after_timeout :: function()
        ) :: response :: any()

  def enforce_timeout(fun, timeout \\ 5_000, after_timeout \\ fn -> nil end) do
    id = "Vigilant.MonitorTimeout.#{inspect(self())}"

    {:ok, child} =
      DynamicSupervisor.start_child(
        Vigilant.MonitorSupervisor,
        %{
          id: id,
          start:
            {GenServer, :start_link, [Vigilant.MonitorTimeout, {self(), timeout, after_timeout}]},
          restart: :transient
        }
      )

    try do
      fun.()
    after
      DynamicSupervisor.terminate_child(Vigilant.MonitorSupervisor, child)
    end
  end
end
