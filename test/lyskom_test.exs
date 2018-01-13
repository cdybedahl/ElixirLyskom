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

end
