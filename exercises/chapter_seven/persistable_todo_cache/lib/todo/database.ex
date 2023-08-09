defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  # Though this is an asynchronous cast, if requests to the database come in faster than they can be handled the process mailbox will grow and increasingly consume memory
  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  # A synchronous call; the to-do server waits while the database returns the response. Though this won't block indefinitely (GenServer.call has a default timeout of 5 seconds), when a request times out it isn't removed from the receiver's mailbox to be processed at some point
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    key
    |> file_name()
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    data =
      case File.read(file_name(key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, state}
  end

  defp file_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end
