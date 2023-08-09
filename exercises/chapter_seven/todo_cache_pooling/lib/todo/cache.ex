defmodule Todo.Cache do
  @moduledoc """
  Todo.Cache maintains a collection of to-do servers and is responsible for their creation and discovery. It is the system entry point: all needed processes are started when the cache process is started.

  It exports only two functions: start/0, which starts the process, and server_process/2, which retrieves a to-do server process (its pid) for a given name, optionally starting the process if it isn’t already running.

  ## Example usage:

    iex> {:ok, cache_pid} = Todo.Cache.start()
    {:ok, #PID<0.196.0>}

    iex> bobs_list = Todo.Cache.server_process(cache_pid, "bobs_list")
    #PID<0.162.0>

    iex> Todo.Server.add_entry(bobs_list, %{date: "bob-date", title: "bob-1"})
    :ok

    iex> Todo.Server.entries(bobs_list)
    [%{date: "bob-date", id: 1, title: "bob-1"}]

    iex> dees_list = Todo.Cache.server_process(cache_pid, "dees_list")
    #PID<0.164.0>

    iex> Todo.Server.add_entry(dees_list, %{date: "dee-date", title: "dee-1"})
    :ok

    iex> Todo.Server.entries(dees_list)
    [%{date: "dee-date", id: 1, title: "dee-1"}]

  Test that persistence works by exiting and restarting the shell session, then running the following to verify that entries exist on startup:

    iex> {:ok, cache_pid} = Todo.Cache.start()
    {:ok, #PID<0.196.0>}

    iex> bobs_list = Todo.Cache.server_process(cache_pid, "bobs_list")
    #PID<0.162.0>

    iex> Todo.Server.entries(bobs_list)
    [%{date: "bob-date", id: 1, title: "bob-1"}]

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
    Todo.Database.start()

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start(todo_list_name)

        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end
end
