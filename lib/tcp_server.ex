defmodule TcpServer do
  require Logger

  def do_listen(port) do
    case :gen_tcp.listen(port, [packet: 0, active: false]) do
      {:ok, listen_socket} -> 
        loop_acceptor(listen_socket)
      {:error, errno} -> 
        Logger.error errno
    end
  end

  def loop_acceptor(listen_socket, cnt\\0) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        spawn(fn -> do_recv(client_socket, 0) end)
        IO.puts(cnt)
        loop_acceptor(listen_socket, cnt + 1)
      {:error, errno } -> 
        Logger.error errno
    end
  end

  def do_recv(client_socket, length) do
    case :gen_tcp.recv(client_socket, length) do
      {:ok, data} -> 
        data_handler(client_socket, data)
      {:error, errno} -> 
        Logger.error errno
    end
  end

  def data_handler(client_socket, data) do
    cond do
      data |> to_string |> String.trim |> String.equivalent? "bye" ->
        do_close(client_socket)
      true -> 
        do_send(client_socket, data)
    end
  end

  def do_send(client_socket, data) do
    case :gen_tcp.send(client_socket, data) do
      :ok -> do_recv(client_socket, 0)
      {:error, errno} -> 
        Logger.error errno
    end
  end

  def do_close(client_socket) do
    :gen_tcp.close(client_socket)
  end
end
