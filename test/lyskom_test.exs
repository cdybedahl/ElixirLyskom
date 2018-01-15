defmodule LyskomTest do
  use ExUnit.Case
  doctest Lyskom

  alias Lyskom.Prot_A.Tokenize

  test "Message to tokens" do
    {type, rest} = Tokenize.next_token("=1 17 { 42HCalle Dybedahl (on a mission from Goddess) 1001 70 }\n")
    assert type == :success

    {n, rest} = Tokenize.next_token(rest)
    assert n == 1

    {n, rest} = Tokenize.next_token(rest)
    assert n == 17

    {n, rest} = Tokenize.next_token(rest)
    assert n == :arraystart

    {n, rest} = Tokenize.next_token(rest)
    assert n == "Calle Dybedahl (on a mission from Goddess)"

    {n, rest} = Tokenize.next_token(rest)
    assert n == 1001

    {n, rest} = Tokenize.next_token(rest)
    assert n == 70

    {n, rest} = Tokenize.next_token(rest)
    assert n == :arrayend

    {n, rest} = Tokenize.next_token(rest)
    assert n == :msgend

    assert rest == ""
  end

  test "Split integer" do
    {type, rest} = Tokenize.next_token("4711")
    assert type == :incomplete

    {n, rest} = Tokenize.continue_token("42\n", rest)
    assert n == 471142
    assert rest == "\n"
  end

  test "Split Hollerith string" do
    {type, rest} = Tokenize.next_token("10H12345")
    assert type == :incomplete

    {str, rest} = Tokenize.continue_token("12345 ", rest)
    assert str == "1234512345"
    assert rest == " "
  end

  test "Array parsing" do
    list = [:start, 0, :arrayempty, 17, 3, :arraystart, 1, 2, 3, 4, 5, 6, 7, 8, 9, :arrayend, :msgend]
    parsed = Lyskom.Parser.process_arrays(list)
    assert Enum.at(parsed,0) == :start
    assert Enum.at(parsed, 1) == []
    assert parsed |> Enum.at(3) |> Enum.at(0) == [1,2,3]
    assert List.last(parsed) == :msgend
    assert Enum.count(parsed) == 5
  end

  test "More array parsing" do
    list = [:start, 1, :arraystart, 17, :arrayend, :msgend]
    parsed = Lyskom.Parser.process_arrays(list)
    assert parsed == [:start, [[17]], :msgend]
  end

  test "Nested array parsing" do
    list = [:start, :level1, 1, :arraystart, :inner, 2, :arraystart, :foo, :bar, :baz, :gazonk, :arrayend, :after, :arrayend, :msgend]
    parsed = Lyskom.Parser.process_arrays(list)
    assert parsed == [:start, :level1, [[ :inner, [[:foo,:bar], [:baz, :gazonk]], :after ]], :msgend ]
  end

end
