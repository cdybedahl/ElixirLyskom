defmodule LyskomTest do
  use ExUnit.Case
  doctest Lyskom

  test "Array parsing" do
    list = [
      :start,
      '0',
      :arrayempty,
      '17',
      '3',
      :arraystart,
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      :arrayend,
      :msgend
    ]

    parsed = Lyskom.Parser.process_arrays(list)
    assert Enum.at(parsed, 0) == :start
    assert Enum.at(parsed, 1) == []
    assert parsed |> Enum.at(3) |> Enum.at(0) == ['1', '2', '3']
    assert List.last(parsed) == :msgend
    assert Enum.count(parsed) == 5
  end

  test "More array parsing" do
    list = [:start, '1', :arraystart, '17', :arrayend, :msgend]
    parsed = Lyskom.Parser.process_arrays(list)
    assert parsed == [:start, [['17']], :msgend]
  end

  test "Nested array parsing" do
    list = [
      :start,
      :level1,
      '1',
      :arraystart,
      :inner,
      '2',
      :arraystart,
      :foo,
      :bar,
      :baz,
      :gazonk,
      :arrayend,
      :after,
      :arrayend,
      :msgend
    ]

    parsed = Lyskom.Parser.process_arrays(list)

    assert parsed == [
             :start,
             :level1,
             [[:inner, [[:foo, :bar], [:baz, :gazonk]], :after]],
             :msgend
           ]
  end
end
