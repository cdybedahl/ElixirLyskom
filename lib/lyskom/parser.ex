defmodule Lyskom.Parser do
  use GenServer
  require Logger

  alias Lyskom.Prot_A.Tokenize

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def incoming(bin) do
    GenServer.cast(@me, {:incoming, bin})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{data: "", tokens: [], incomplete: nil}}
  end

  def handle_cast({:incoming, bin}, state) do
    state = put_in(state.data, state.data <> bin)
    state = process_data(state)
    state = process_tokens(state)
    {:noreply, state}
  end

  ### Internals

  ## Take care of data coming in from the socket
  defp process_data(state = %{data: ""}) do
    state
  end

  defp process_data(%{data: bin, tokens: t, incomplete: nil}) do
    {next, rest} = Tokenize.next_token(bin)

    case next do
      :incomplete ->
        process_data(%{data: "", tokens: t, incomplete: rest})

      _ ->
        process_data(%{data: rest, tokens: [next | t], incomplete: nil})
    end
  end

  defp process_data(%{data: bin, tokens: t, incomplete: prev}) do
    {next, rest} = Tokenize.continue_token(bin, prev)
    process_data(%{data: rest, tokens: [next | t], incomplete: nil})
  end

  ## Chunk up tokens into complete messages and pass them on
  defp process_tokens(state = %{tokens: []}) do
    state
  end

  defp process_tokens(state = %{tokens: list}) do
    list = Enum.reverse(list)
    index = Enum.find_index(list, fn item -> item == :msgend end)

    case index do
      nil ->
        state

      _ ->
        {msg, list} = Enum.split(list, index)
        [:msgend | list] = list
        msg = process_arrays(msg)
        Lyskom.Server.incoming(msg)
        state = put_in(state.tokens, Enum.reverse(list))
        process_tokens(state)
    end
  end

  @doc """
  process_arrays walks through a list of items and turns Protocol A arrays into
  lists of lists of elements.
  """
  def process_arrays(list) do
    Enum.reverse(_process_arrays(list, []))
  end

  defp _process_arrays([], acc) do
    acc
  end

  defp _process_arrays([0, :arrayempty | tail], acc) do
    _process_arrays(tail, [[] | acc])
  end

  defp _process_arrays([n, :arraystart | tail], acc) when is_integer(n) do
    tail = process_arrays(tail)
    index_end = Enum.find_index(tail, fn item -> item == :arrayend end)
    {array, rest} = Enum.split(tail, index_end)
    item_length = div(Enum.count(array), n)
    array = Enum.chunk_every(array, item_length)
    [:arrayend | rest] = rest
    _process_arrays(rest, [array | acc])
  end

  defp _process_arrays([head | tail], acc) do
    _process_arrays(tail, [head | acc])
  end
end
