defmodule VigilantTest do
  use ExUnit.Case, async: true
  doctest Vigilant

  describe ".limit_memory/2" do
    defmodule MemoryLeak do
      def leak(x \\ %{}), do: ["leaky leaky leaky leaky leaky leaky" | x] |> leak()
    end

    test "kills a process when memory usage gets too high" do
      {:ok, agent} =
        Agent.start(fn ->
          Vigilant.limit_memory(100)
          []
        end)

      assert {:killed, _} =
               catch_exit(Agent.update(agent, fn s -> MemoryLeak.leak(s) end, 10_000))
    end

    test "does not kill well behaved process" do
      {:ok, agent} =
        Agent.start(fn ->
          Vigilant.limit_memory(5)
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
                   Vigilant.enforce_timeout(fn -> Process.sleep(1200) end, 100)
                 end)
               )
    end

    test "does not kill the process when work completes in time" do
      {:ok, agent} = Agent.start(fn -> nil end)

      assert :ok =
               Agent.update(agent, fn _s ->
                 fn ->
                   Process.sleep(50)
                   500
                 end
                 |> Vigilant.enforce_timeout(100)
               end)
    end
  end

  describe ".limit_message_queue/2" do
    test "kills process after message queue grows too much" do
      pid =
        spawn(fn ->
          receive do
            :not_matching -> :ok
          end
        end)

      Vigilant.limit_message_queue(pid, 100)

      for _ <- 1..101, do: send(pid, :msg)

      # Wait a little more than one tick interval
      Process.sleep(600)

      refute Process.alive?(pid)
    end

    test "does not kill process with message queue size below the limit" do
      pid =
        spawn(fn ->
          receive do
            :not_matching -> :ok
          end
        end)

      Vigilant.limit_message_queue(pid, 100)

      for _ <- 1..99, do: send(pid, :msg)

      # Wait a little more than one tick interval
      Process.sleep(600)

      assert Process.alive?(pid)
    end
  end
end
