defmodule CalangobotTest do
  use ExUnit.Case
  doctest Calangobot

  test "greets the world" do
    assert Calangobot.hello() == :world
  end
end
