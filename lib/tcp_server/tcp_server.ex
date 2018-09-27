defmodule TcpServer do
    use GenServer
    require Logger

    defstruct(
        active_conns: 0,
        visitor: 0
    )
    @type t :: %__MODULE__{active_conns: integer, visitor: integer}
  
    def start_link(port) do
      GenServer.start_link(__MODULE__, port, name: __MODULE__)
    end
  
    def init(port) do
      case do_listen(port) do
        {true, listen_socket} -> 
          Task.start_link( fn -> loop_acceptor(listen_socket) end)
        {false, errno} ->
          Logger.error errno 
      end
        {:ok, %__MODULE__{}}
    end

    def handle_cast({:add_conn}, state) do
        {:noreply,
          %{state | visitor: state.visitor + 1, 
          active_conns: state.active_conns + 1}
        }
    end
  
    def do_listen(port) do
      case :gen_tcp.listen(port, [packet: 0, active: false]) do
        {:ok, listen_socket} -> 
          {true, listen_socket}
        {:error, errno} -> 
          {false, errno}
      end
    end
  
    def loop_acceptor(listen_socket) do
      case :gen_tcp.accept(listen_socket) do
        {:ok, client_socket} ->
          add_conns()
          spawn(fn -> do_recv(client_socket, 0) end)
          spawn( fn -> IO.inspect(:sys.get_state(__MODULE__)) end)
          loop_acceptor(listen_socket)
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

    #clinetAPI

    def add_conns() do
      GenServer.cast(__MODULE__,{:add_conn})
    end
  end
  