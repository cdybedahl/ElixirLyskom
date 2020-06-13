defmodule Lyskom.Tokenize do
  require Logger
  alias Lyskom.Socket

  ### External API

  def incoming(state, msg) do
    process(Map.update!(state, :tok_data, fn str -> str <> msg end))
  end

  ### Internal functions
  defp process(state = %Socket{tok_data: ""}) do
    state
  end

  defp process(
         state = %Socket{tok_data: <<next_char::8, rest::binary>>, tok_state: :start, tok_acc: []}
       ) do
    case next_char do
      ?= ->
        Lyskom.Socket.incoming_token(self(), :success)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      ?% ->
        Lyskom.Socket.incoming_token(self(), :failure)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      ?: ->
        Lyskom.Socket.incoming_token(self(), :async)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      ?{ ->
        Lyskom.Socket.incoming_token(self(), :arraystart)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      ?} ->
        Lyskom.Socket.incoming_token(self(), :arrayend)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      ?* ->
        Lyskom.Socket.incoming_token(self(), :arrayempty)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      10 ->
        Lyskom.Socket.incoming_token(self(), :msgend)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      32 ->
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      _ ->
        process(%Socket{state | tok_data: rest, tok_state: :content, tok_acc: [next_char]})
    end
  end

  defp process(
         state = %Socket{
           tok_data: <<next_char::8, rest::binary>>,
           tok_state: :content,
           tok_acc: acc
         }
       ) do
    case next_char do
      32 ->
        Lyskom.Socket.incoming_token(self(), Enum.reverse(acc))
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      10 ->
        Lyskom.Socket.incoming_token(self(), Enum.reverse(acc))
        Lyskom.Socket.incoming_token(self(), :msgend)
        process(%Socket{state | tok_data: rest, tok_state: :start, tok_acc: []})

      ?H ->
        process(%Socket{
          state
          | tok_data: rest,
            tok_state: List.to_integer(Enum.reverse(acc)),
            tok_acc: []
        })

      _ ->
        process(%Socket{state | tok_data: rest, tok_state: :content, tok_acc: [next_char | acc]})
    end
  end

  defp process(
         state = %Socket{
           tok_data: data = <<next_char::8, rest::binary>>,
           tok_state: n,
           tok_acc: acc
         }
       )
       when is_integer(n) do
    case n do
      0 ->
        result =
          acc
          |> Enum.reverse()
          |> IO.iodata_to_binary()

        Lyskom.Socket.incoming_token(self(), result)

        process(%Socket{state | tok_data: data, tok_state: :start, tok_acc: []})

      _ when n > 0 ->
        process(%Socket{state | tok_data: rest, tok_state: n - 1, tok_acc: [next_char | acc]})
    end
  end

  ### Internals

  @doc """
  process_arrays walks through a list of items and turns Protocol A arrays into
  lists of lists of elements.
  """
  def process_arrays(list) do
    Enum.reverse(process_arrays(list, []))
  end

  defp process_arrays([], acc) do
    acc
  end

  defp process_arrays(['0', :arrayempty | tail], acc) do
    process_arrays(tail, [[] | acc])
  end

  defp process_arrays([n, :arraystart | tail], acc) do
    n = List.to_integer(n)
    tail = process_arrays(tail)
    index_end = Enum.find_index(tail, fn item -> item == :arrayend end)
    {array, rest} = Enum.split(tail, index_end)
    item_length = div(Enum.count(array), n)
    array = Enum.chunk_every(array, item_length)
    [:arrayend | rest] = rest
    process_arrays(rest, [array | acc])
  end

  defp process_arrays([head | tail], acc) do
    process_arrays(tail, [head | acc])
  end
end
