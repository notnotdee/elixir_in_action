defmodule Todo.Cache do
  @moduledoc """
  Todo.Cache maintains a collection of to-do servers and is responsible for their creation and discovery. It is the system entry point: all needed processes are started when the cache process is started.
  """

  use GenServer

  ## Interface functions ##

  def start_link(_) do
    IO.puts("Starting cache...")

    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(todo_list_name) do
    GenServer.call(__MODULE__, {:server_process, todo_list_name})
  end

  ## GenServer callbacks ##

  @impl GenServer
  def init(_) do
    # Todo.Database.start_link() # Moved to supervision tree

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start_link(todo_list_name)

        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end
end
