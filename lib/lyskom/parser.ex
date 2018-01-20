defmodule Lyskom.Parser do
  use GenServer
  require Logger

  @me __MODULE__

  ### API

  def start_link(_) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def incoming(token) do
    GenServer.cast(@me, {:incoming, token})
  end

  ### Callbacks

  def init(:no_args) do
    {:ok, %{tokens: []}}
  end

  def handle_cast({:incoming, :msgend}, state) do
    msg = Enum.reverse(state.tokens)
    msg = process_arrays(msg)
    Logger.debug("Message: #{inspect(msg)}")
    {:noreply, %{state | tokens: []}}
  end

  def handle_cast({:incoming, token}, state) do
    {:noreply, update_in(state[:tokens], fn l -> [token | l] end)}
  end

  ### Internals

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

  defp _process_arrays(['0', :arrayempty | tail], acc) do
    _process_arrays(tail, [[] | acc])
  end

  defp _process_arrays([n, :arraystart | tail], acc) do
    n = List.to_integer(n)
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
