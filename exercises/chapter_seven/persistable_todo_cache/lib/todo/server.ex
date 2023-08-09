defmodule Todo.Server do
  @moduledoc """
  Todo.Server is used to create and return a pid of a to-do server process which can be used to perform operations on a single to-do list. Allows multiple clients to work on a single to-do list.

  ### Example usage:
    iex> {:ok, pid} = Todo.Server.start()
    #PID<0.164.0>

    iex> Todo.Server.add_entry(pid, %{title: 'entry-1', date: 'date-1'})
    :ok

    iex> Todo.Server.add_entry(pid, %{title: 'entry-2', date: 'date-2'})
    :ok

    iex> Todo.Server.entries(pid)
    [
    %{date: 'date-1', id: 1, title: 'entry-1'},
    %{date: 'date-2', id: 2, title: 'entry-2'}
    ]

    iex> Todo.Server.update_entry(pid, %{date: 'date-new', title: 'entry-new', id: 1})
    :ok

    iex> Todo.Server.delete_entry(pid, 2)
    :ok

    iex> Todo.Server.entries(pid)
    [%{date: 'date-new', id: 1, title: 'entry-new'}]
  """
  use GenServer

  ## Client API ##

  def start(path_name) do
    GenServer.start(__MODULE__, path_name)
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def update_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  def entries(todo_server) do
    GenServer.call(todo_server, {:entries})
  end

  ## GenServer callbacks ##

  @impl GenServer
  def init(path_name) do
    {:ok,
     {
       path_name,
       Todo.Database.get(path_name) || Todo.List.new()
     }}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {path_name, todo_list}) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(path_name, new_state)

    {:noreply, {path_name, new_state}}
  end

  @impl GenServer
  def handle_cast({:update_entry, new_entry}, {path_name, todo_list}) do
    new_state = Todo.List.update_entry(todo_list, new_entry)
    Todo.Database.store(path_name, new_state)

    {:noreply, {path_name, new_state}}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, {path_name, todo_list}) do
    new_state = Todo.List.delete_entry(todo_list, entry_id)
    Todo.Database.store(path_name, new_state)

    {:noreply, {path_name, new_state}}
  end

  @impl GenServer
  def handle_call({:entries}, _, {path_name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list),
      {path_name, todo_list}
    }
  end
end
