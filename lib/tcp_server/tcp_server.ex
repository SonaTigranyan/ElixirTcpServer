defmodule TcpServer do
  use GenServer
  require Logger

  defstruct(
    active_conns: [],
    visitor: 0
  )

  @type t :: %__MODULE__{active_conns: list(port), visitor: integer}

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    case do_listen(port) do
      {true, listen_socket} ->
        Task.start_link(fn -> loop_acceptor(listen_socket) end)

      {false, errno} ->
        Logger.error(errno)
    end

    {:ok, %__MODULE__{}}
  end

  def handle_cast({:add_conn, client_socket}, state) do
    {:noreply,
     %{state | visitor: state.visitor + 1, active_conns: state.active_conns ++ [client_socket]}}
  end

  def handle_cast({:remove_conn, client_socket}, state) do
    {:noreply, %{state | active_conns: state.active_conns -- [client_socket]}}
  end

  def handle_call({:show_visitor_number}, _, state) do
    {:reply, state.visitor, state}
  end

  def do_listen(port) do
    case :gen_tcp.listen(port, packet: 0, active: false) do
      {:ok, listen_socket} ->
        {true, listen_socket}

      {:error, errno} ->
        {false, errno}
    end
  end

  def loop_acceptor(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        add_conns(client_socket)
        show_post_conn_info(client_socket)

        spawn(fn ->
          do_recv(client_socket, 0)
        end)

        ## :sys.get_state(__MODULE__)
        loop_acceptor(listen_socket)

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  def do_recv(client_socket, length) do
    case :gen_tcp.recv(client_socket, length) do
      {:ok, data} ->
        data_handler(client_socket, data)

      {:error, :closed} ->
        Logger.info("client closed")

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  def data_handler(client_socket, data) do
    cond do
      data |> to_string |> String.trim() |> String.equivalent?("bye") ->
        do_close(client_socket)

      true ->
        do_send(client_socket, data)
    end
  end

  def do_send(client_socket, data) do
    case :gen_tcp.send(client_socket, data) do
      :ok ->
        do_recv(client_socket, 0)

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  def show_post_conn_info(client_socket) do
    case :inet.peername(client_socket) do
      {:ok, {address, port}} ->
        spawn(fn -> IO.inspect({show_visitor_nummber(), address, port}) end)

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  def show_conns_info() do
    :sys.get_state(__MODULE__)
    |> Map.get(:active_conns)
    |> Enum.map(fn port -> :inet.peername(port) |> elem(1) end)
  end

  def do_close(client_socket) do
    :gen_tcp.close(client_socket)
    remove_conns(client_socket)
  end

  def close_conns() do
    %{:active_conns => active_conns} = :sys.get_state(__MODULE__)
    Enum.each(active_conns, fn conn -> do_close(conn) end)
  end

  # clinetAPI

  def add_conns(client_socket) do
    GenServer.cast(__MODULE__, {:add_conn, client_socket})
  end

  def remove_conns(client_socket) do
    GenServer.cast(__MODULE__, {:remove_conn, client_socket})
  end

  def show_visitor_nummber() do
    GenServer.call(__MODULE__, {:show_visitor_number})
  end
end
