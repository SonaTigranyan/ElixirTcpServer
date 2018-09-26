defmodule TcpServerTest do
  use ExUnit.Case
  doctest TcpServer

  test "greets the world" do
    assert TcpServer.hello() == :world
  end
end
