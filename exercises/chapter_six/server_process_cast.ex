defmodule ServerProcess do
  @moduledoc """
  ### Example usage:
    iex> pid = ServerProcess.start(KVS)
    #PID<0.164.0>

    iex> ServerProcess.cast(pid, {:put, :some_key, :some_value})
    {:cast, {:put, :some_key, :some_value}}

    iex> ServerProcess.call(pid, {:get, :some_key})
    :some_value
  """

  def start(callback_module) do
    spawn(fn ->
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

      # To handle a cast, you need the callback func handle_cast/2. this func must handle the message and return the new state.
      # In the server loop, you then invoke this func and loop with the new state
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

defmodule KVS do
  ## Client API ##

  def start do
    ServerProcess.start(__MODULE__)
  end

  def put(pid, key, value) do
    ServerProcess.cast(pid, {:put, key, value})
  end

  def get(pid, key) do
    ServerProcess.call(pid, {:get, key})
  end

  ## GenServer callbacks ##

  def init, do: %{}

  def handle_call({:get, key}, state) do
    {Map.get(state, key), state}
  end

  def handle_cast({:put, key, value}, state) do
    Map.put(state, key, value)
  end
end
