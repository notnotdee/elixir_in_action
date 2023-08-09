defmodule Todo.Cache do
  @moduledoc """
  Todo.Cache is used to create and return a pid of a to-do server process that corresponds to the given to-do list name. It maintains a collection of to-do servers and is responsible for their creation and discovery. å

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

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, {:server_process, todo_list_name})
  end

  ## GenServer callbacks ##

  @impl GenServer
  def init(_) do
    Todo.Database.start()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, state) do
    case Map.fetch(state, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, state}

      :error ->
        {:ok, new_server} = Todo.Server.start(todo_list_name)

        {
          :reply,
          new_server,
          Map.put(state, todo_list_name, new_server)
        }
    end
  end
end
