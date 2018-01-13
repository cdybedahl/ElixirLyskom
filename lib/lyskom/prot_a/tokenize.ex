defmodule Lyskom.Prot_A.Tokenize do

  def next_token(bin) do
    _next_token(:start, bin)
  end

  def continue_token(bin, {:integer, acc}) do
    _next_token(:integer, bin, acc)
  end

  def continue_token(bin, {:hollerith, n, acc}) do
    _next_token(:hollerith, n, bin, acc)
  end

  # Protocol Error
  def _next_token(:start, << "%%", message::binary >>) do
    raise "Protocol Error: #{message}"
  end

  # Successful reply
  def _next_token(:start, << "=", tail::binary >>) do
    {:success, tail}
  end

  # Failure reply
  def _next_token(:start, << "%", tail::binary >>) do
    {:fail, tail}
  end

  # Asynchronous message
  def _next_token(:start, << ":", tail::binary>>) do
    {:async, tail}
  end

  # Start of an array
  def _next_token(:start, << "{", tail::binary >>) do
    {:arraystart, tail}
  end

  # End of an array
  def _next_token(:start, << "}", tail::binary >>) do
    {:arrayend, tail}
  end

  # Marker for an empty array
  def _next_token(:start, << "*", tail::binary >>) do
    {:arrayempty, tail}
  end

  # End of a message
  def _next_token(:start, << "\n", tail::binary >>) do
    {:msgend, tail}
  end

  # Space after a fixed-length item, skip
  def _next_token(:start, << " ", tail::binary >>) do
    _next_token(:start, tail)
  end

  # Integer
  def _next_token(:start, << head::8, tail::binary>>) do
    _next_token(:integer, tail, [head])
  end

  def _next_token(:integer, << " ", tail::binary>>, acc) do
    n = acc |> Enum.reverse |> List.to_integer
    {n, tail}
  end

  def _next_token(:integer, bin = << "\n", _tail::binary>>, acc) do
    n = acc |> Enum.reverse |> List.to_integer
    {n, bin}
  end

  def _next_token(:integer, << "H", tail::binary >>, acc) do
    n = acc |> Enum.reverse |> List.to_integer
    _next_token(:hollerith, n, tail, [])
  end

  def _next_token(:integer, <<head::8, tail::binary>>, acc) do
    _next_token(:integer, tail, [head|acc])
  end

  # FIXME: Add support for floats

  def _next_token(:integer, "", acc) do
    {:incomplete, {:integer, acc}}
  end

  # Hollerith string
  def _next_token(:hollerith, 0, tail, acc) do
    str = acc |> Enum.reverse |> to_string
    {str, tail}
  end

  def _next_token(:hollerith, n, << head::8, tail::binary >>, acc) do
    _next_token(:hollerith, n-1, tail, [head|acc])
  end

  def _next_token(:hollerith, n, "", acc) do
    {:incomplete, {:hollerith, n, acc}}
  end

end
