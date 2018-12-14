defmodule Lyskom.ProtA.Tokenize do
  use GenServer
  require Logger

  @me __MODULE__

  ### API

  def start_link(name_base) do
    GenServer.start_link(@me, name_base, name: _name(name_base))
  end

  def incoming(data, name) do
    GenServer.cast(_name(name), {:incoming, data})
  end

  ### Callbacks

  def init(name_base) do
    {:ok, %{name_base: name_base, data: "", state: :start, acc: []}}
  end

  def handle_cast({:incoming, data}, state) do
    Process.send_after(GenServer.whereis(_name(state.name_base)), :process, 0)
    {:noreply, update_in(state.data, fn old -> old <> data end)}
  end

  def handle_info(:process, state) do
    {:noreply, process(state)}
  end

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:tokenize, ref}}}
  end

  ############################################
  # Processing
  ############################################

  def process(state = %{data: ""}) do
    state
  end

  # FIXME: New state after a token loses name_base
  def process(%{name_base: name, data: <<next_char::8, rest::binary>>, state: :start, acc: []}) do
    case next_char do
      ?= ->
        Lyskom.Parser.incoming(:success, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      ?% ->
        Lyskom.Parser.incoming(:failure, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      ?: ->
        Lyskom.Parser.incoming(:async, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      ?{ ->
        Lyskom.Parser.incoming(:arraystart, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      ?} ->
        Lyskom.Parser.incoming(:arrayend, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      ?* ->
        Lyskom.Parser.incoming(:arrayempty, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      10 ->
        Lyskom.Parser.incoming(:msgend, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      32 ->
        process(%{name_base: name, data: rest, state: :start, acc: []})

      _ ->
        process(%{name_base: name, data: rest, state: :content, acc: [next_char]})
    end
  end

  def process(%{name_base: name, data: <<next_char::8, rest::binary>>, state: :content, acc: acc}) do
    case next_char do
      32 ->
        Lyskom.Parser.incoming(Enum.reverse(acc), name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      10 ->
        Lyskom.Parser.incoming(Enum.reverse(acc), name)
        Lyskom.Parser.incoming(:msgend, name)
        process(%{name_base: name, data: rest, state: :start, acc: []})

      ?H ->
        process(%{name_base: name, data: rest, state: List.to_integer(Enum.reverse(acc)), acc: []})

      _ ->
        process(%{name_base: name, data: rest, state: :content, acc: [next_char | acc]})
    end
  end

  def process(%{name_base: name, data: data = <<next_char::8, rest::binary>>, state: n, acc: acc})
      when is_integer(n) do
    case n do
      0 ->
        acc
        |> Enum.reverse()
        |> IO.iodata_to_binary()
        |> Lyskom.Parser.incoming(name)

        process(%{name_base: name, data: data, state: :start, acc: []})

      _ when n > 0 ->
        process(%{name_base: name, data: rest, state: n - 1, acc: [next_char | acc]})
    end
  end
end
