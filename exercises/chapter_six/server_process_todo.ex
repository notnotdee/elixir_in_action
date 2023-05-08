defmodule TodoServer do
  @moduledoc """
  ### Example usage:
    iex> pid = TodoServer.start()
    #PID<0.164.0>

    iex> TodoServer.add_entry(pid, %{title: 'entry-1', date: 'date-1'})
    {:cast, {:add_entry, %{date: 'date-1', title: 'entry-1'}}}

    iex> TodoServer.add_entry(%{title: 'entry-2', date: 'date-2'})
    {:cast, {:add_entry, %{date: 'date-2', title: 'entry-2'}}}

    iex> TodoServer.entries(pid)
    [
    %{date: 'date-1', id: 1, title: 'entry-1'},
    %{date: 'date-2', id: 2, title: 'entry-2'}
    ]

    iex> TodoServer.update_entry(pid, %{date: 'date-new', title: 'entry-new', id: 1})
    {:cast, {:update_entry, %{date: 'date-new', id: 1, title: 'entry-new'}}}

    iex> TodoServer.delete_entry(pid, 2)
    {:cast, {:delete_entry, 2}}

    iex> TodoServer.entries(pid)
    [%{date: 'date-new', id: 1, title: 'entry-new'}]
  """

  ## Interface functions ##

  def start do
    ServerProcess.start(__MODULE__)
  end

  def add_entry(server_pid, new_entry) do
    ServerProcess.cast(server_pid, {:add_entry, new_entry})
  end

  def update_entry(server_pid, new_entry) do
    ServerProcess.cast(server_pid, {:update_entry, new_entry})
  end

  def delete_entry(server_pid, entry_id) do
    ServerProcess.cast(server_pid, {:delete_entry, entry_id})
  end

  def entries(server_pid) do
    ServerProcess.call(server_pid, {:entries})
  end

  ## Callback functions ##

  def init do
    TodoList.new()
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, new_entry}, todo_list) do
    TodoList.update_entry(todo_list, new_entry)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  def handle_call({:entries}, todo_list) do
    {TodoList.entries(todo_list), todo_list}
  end
end

defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      Process.register(self(), :todo_server)

      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} =
          callback_module.handle_call(
            request,
            current_state
          )

        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state =
          callback_module.handle_cast(
            request,
            current_state
          )

        loop(callback_module, new_state)
    end
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} ->
        response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
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
