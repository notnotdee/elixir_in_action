defmodule TodoServer do
  @moduledoc """
  A to-do server process that can be used to manage one to-do list for a long time.

  ### Example usage:
    iex> pid = TodoServer.start()
    #PID<0.164.0>

    iex> TodoServer.add_entry(%{title: 'entry-1', date: 'date-1'})
    :ok

    iex> TodoServer.add_entry(%{title: 'entry-2', date: 'date-2'})
    :ok

    iex> TodoServer.entries()
    [
    %{date: 'date-1', id: 1, title: 'entry-1'},
    %{date: 'date-2', id: 2, title: 'entry-2'}
    ]

    iex> TodoServer.update_entry(%{date: 'date-new', title: 'entry-new', id: 1})
    :ok

    iex> TodoServer.delete_entry(2)
    :ok

    iex> TodoServer.entries()
    [%{date: 'date-new', id: 1, title: 'entry-new'}]
  """

  use GenServer

  ## Client API ##

  def start do
    GenServer.start(__MODULE__, %{}, name: __MODULE__)
  end

  def add_entry(new_entry) do
    GenServer.cast(__MODULE__, {:add_entry, new_entry})
  end

  def update_entry(new_entry) do
    GenServer.cast(__MODULE__, {:update_entry, new_entry})
  end

  def delete_entry(entry_id) do
    GenServer.cast(__MODULE__, {:delete_entry, entry_id})
  end

  def entries() do
    GenServer.call(__MODULE__, {:entries})
  end

  ## GenServer callbacks ##

  @impl GenServer
  def init(_) do
    {:ok, TodoList.new()}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, todo_list) do
    new_state = TodoList.add_entry(todo_list, new_entry)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:update_entry, new_entry}, todo_list) do
    new_state = TodoList.update_entry(todo_list, new_entry)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, todo_list) do
    new_state = TodoList.delete_entry(todo_list, entry_id)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:entries}, _, todo_list) do
    {:reply, TodoList.entries(todo_list), todo_list}
  end
end

defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %__MODULE__{},
      &add_entry(&2, &1)
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

    %__MODULE__{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(todo_list, entry_id, updater_func) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_func.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)

        %__MODULE__{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    %__MODULE__{todo_list | entries: Map.delete(todo_list.entries, entry_id)}
  end

  def entries(todo_list) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry end)
    |> Enum.map(fn {_, entry} -> entry end)
  end
end
