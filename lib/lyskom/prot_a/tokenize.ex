defmodule Lyskom.ProtA.Tokenize do
  use GenServer
  require Logger

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def incoming(data) do
    GenServer.cast(@me, {:incoming, data})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{data: "", state: :start, acc: []}}
  end

  def handle_cast({:incoming, data}, state) do
    Process.send_after(@me, :process, 0)
    {:noreply, update_in(state.data, fn old -> old <> data end)}
  end

  def handle_info(:process, state) do
    {:noreply, process(state)}
  end

  def _name(ref) do
    {:via, Registry, {Lyskom.Registry, {:tokenize, ref }}}
  end

############################################
  # Processing
  ############################################

  def process(state = %{data: ""}) do
    state
  end

  def process(%{data: <<next_char::8, rest::binary>>, state: :start, acc: []}) do
    case next_char do
      ?= ->
        Lyskom.Parser.incoming(:success)
        process(%{data: rest, state: :start, acc: []})

      ?% ->
        Lyskom.Parser.incoming(:failure)
        process(%{data: rest, state: :start, acc: []})

      ?: ->
        Lyskom.Parser.incoming(:async)
        process(%{data: rest, state: :start, acc: []})

      ?{ ->
        Lyskom.Parser.incoming(:arraystart)
        process(%{data: rest, state: :start, acc: []})

      ?} ->
        Lyskom.Parser.incoming(:arrayend)
        process(%{data: rest, state: :start, acc: []})

      ?* ->
        Lyskom.Parser.incoming(:arrayempty)
        process(%{data: rest, state: :start, acc: []})

      10 ->
        Lyskom.Parser.incoming(:msgend)
        process(%{data: rest, state: :start, acc: []})

      32 ->
        process(%{data: rest, state: :start, acc: []})

      _ ->
        process(%{data: rest, state: :content, acc: [next_char]})
    end
  end

  def process(%{data: <<next_char::8, rest::binary>>, state: :content, acc: acc}) do
    case next_char do
      32 ->
        Lyskom.Parser.incoming(Enum.reverse(acc))
        process(%{data: rest, state: :start, acc: []})

      10 ->
        Lyskom.Parser.incoming(Enum.reverse(acc))
        Lyskom.Parser.incoming(:msgend)
        process(%{data: rest, state: :start, acc: []})

      ?H ->
        process(%{data: rest, state: List.to_integer(Enum.reverse(acc)), acc: []})

      _ ->
        process(%{data: rest, state: :content, acc: [next_char | acc]})
    end
  end

  def process(%{data: data = <<next_char::8, rest::binary>>, state: n, acc: acc})
      when is_integer(n) do
    case n do
      0 ->
        acc
        |> Enum.reverse()
        |> IO.iodata_to_binary()
        |> to_utf8
        |> Lyskom.Parser.incoming()

        process(%{data: data, state: :start, acc: []})

      _ when n > 0 ->
        process(%{data: rest, state: n - 1, acc: [next_char | acc]})
    end
  end

  def to_utf8(bin) do
    {:ok, str} = Codepagex.to_string(bin, :iso_8859_1)
    str
  end
end
