defmodule ProcessMonitorTest do
  use ExUnit.Case
  doctest ProcessMonitor

  defmodule MemoryLeak do
    def leak(x \\ %{}), do: ["leaky leaky leaky leaky leaky leaky" | x] |> leak()
  end

  test "kills a process when memory usage gets too high" do
    {:ok, agent} =
      Agent.start(fn ->
        ProcessMonitor.monitor(100)
        []
      end)

    assert {:killed, _} = catch_exit(Agent.update(agent, fn s -> MemoryLeak.leak(s) end))
  end

  test "does not kill well behaved process" do
    {:ok, agent} =
      Agent.start(fn ->
        ProcessMonitor.monitor(5)
        5
      end)

    Agent.update(agent, fn s -> s * 100 end)
    Agent.update(agent, fn s -> s * 100 end)
    Agent.update(agent, fn s -> s * 100 end)
    Agent.update(agent, fn s -> s * 100 end)
    Agent.update(agent, fn s -> s * 100 end)

    assert Agent.get(agent, fn s -> s end) == 50_000_000_000
  end
end
