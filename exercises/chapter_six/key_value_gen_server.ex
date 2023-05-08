defmodule KVS do
  @moduledoc """
  ### Example usage:
    iex> KVS.start()
    {:ok, #PID<0.112.0>}

    iex> KVS.put(:some_key, :some_value)
    :ok

    iex> KVS.get(:some_key)
    :some_value
  """

  use GenServer

  ## Client API ##

  @doc """
  GenServer.start/2 returns only after the init/1 callback has finished in the server process. Consequently, the client process that starts the server is blocked until the server process is initialized.
  """
  def start do
    GenServer.start(__MODULE__, %{}, name: __MODULE__)
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  @doc """
  GenServer.call/2 doesn't wait indefinitely for a response. By default, if the response message doesn't arrive in five seconds, an error is raised in the client process. You can alter this by using an optional third argument `timeout`, where the timeout is given in milliseconds.
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  ## GenServer callbacks ##

  # You can get a compile-time warning here if you tell the compiler that the function being defined is supposed to satisfy a contract by some behaviour. To do this, you need to provide the `@impl` module attribute immediately before the first clause of the callback function
  @impl GenServer
  def init(init_arg \\ %{}) do
    {:ok, init_arg}
  end

  @impl GenServer
  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    {:reply, Map.get(state, key), state}
  end
end
