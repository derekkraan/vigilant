defmodule ProcessMonitorTest do
  use ExUnit.Case
  doctest ProcessMonitor

  describe ".limit_memory_mb/2" do
    defmodule MemoryLeak do
      def leak(x \\ %{}), do: ["leaky leaky leaky leaky leaky leaky" | x] |> leak()
    end

    test "kills a process when memory usage gets too high" do
      {:ok, agent} =
        Agent.start(fn ->
          ProcessMonitor.limit_memory_mb(self(), 100)
          []
        end)

      assert {:killed, _} = catch_exit(Agent.update(agent, fn s -> MemoryLeak.leak(s) end))
    end

    test "does not kill well behaved process" do
      {:ok, agent} =
        Agent.start(fn ->
          ProcessMonitor.limit_memory_mb(self(), 5)
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

  describe ".enforce_timeout/3" do
    test "kills the process when timeout is exceeded" do
      {:ok, agent} = Agent.start(fn -> nil end)

      assert {:killed, _} =
               catch_exit(
                 Agent.update(agent, fn _s ->
                   ProcessMonitor.enforce_timeout(fn -> Process.sleep(1200) end, 1000)
                 end)
               )
    end

    test "does not kill the process when work completes in time" do
      {:ok, agent} = Agent.start(fn -> nil end)

      assert :ok =
               Agent.update(agent, fn _s ->
                 fn ->
                   Process.sleep(1000)
                   500
                 end
                 |> ProcessMonitor.enforce_timeout(1200)
               end)
    end
  end
end
