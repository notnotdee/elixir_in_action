defmodule Todo.Server do
  @moduledoc """
  Todo.Server is used to create and return a pid of a to-do server process which can be used to perform operations on a single to-do list.

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

  def start do
    GenServer.start(__MODULE__, nil)
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
  def init(_) do
    {:ok, Todo.List.new()}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, todo_list) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:update_entry, new_entry}, todo_list) do
    new_state = Todo.List.update_entry(todo_list, new_entry)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, todo_list) do
    new_state = Todo.List.delete_entry(todo_list, entry_id)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:entries}, _, todo_list) do
    {:reply, Todo.List.entries(todo_list), todo_list}
  end
end
