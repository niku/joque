defmodule JoqueTest do
  use ExUnit.Case
  doctest Joque

  test "greets the world" do
    assert Joque.hello() == :world
  end
end
