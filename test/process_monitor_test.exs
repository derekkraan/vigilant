defmodule ProcessMonitorTest do
  use ExUnit.Case
  doctest ProcessMonitor

  test "greets the world" do
    assert ProcessMonitor.hello() == :world
  end
end
