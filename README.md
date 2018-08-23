# Vigilant

Vigilant keeps watch over your processes and kills them if they misbehave.

Examples:

```elixir
# limit memory of process to 5mb
:ok = Vigilant.limit_memory(self(), 5)

# equivalent to

:ok = Vigilant.limit_memory(5)

# enforce a timeout
Vigilant.enforce_timeout(fn ->
  Process.sleep(10000000000)
end, 1000, fn ->
  Logger.debug("process killed because timeout was exceeded")
end)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `vigilant` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vigilant, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/vigilant](https://hexdocs.pm/vigilant).

