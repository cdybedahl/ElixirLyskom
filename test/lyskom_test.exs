defmodule LyskomTest do
  use ExUnit.Case
  doctest Lyskom

  test "greets the world" do
    assert Lyskom.hello() == :world
  end
end
