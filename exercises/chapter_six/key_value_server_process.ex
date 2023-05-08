defmodule ServerProcess do
  @moduledoc """
  ### Example usage:
    iex> pid = ServerProcess.start(KeyValueStore)
    #PID<0.164.0>

    iex> ServerProcess.call(pid, {:put, :some_key, :some_value})
    :ok

    iex> ServerProcess.call(pid, {:get, :some_key})
    :some_value
  """

  # the return value of start/1 is a pid which can be used
  # to send messages to the request process
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  defp loop(callback_module, current_state) do
    receive do
      # expect a message in the form of a {request, caller} tuple
      {request, caller} ->
        # the callback function handle_call/2 takes the request
        # payload and the current state and it must return a
        # {response, new_state} tuple
        {response, new_state} =
          callback_module.handle_call(
            request,
            current_state
          )

        # the generic code can then send the response back to
        # the caller and continue looping with the new state
        send(caller, {:response, response})

        loop(callback_module, new_state)
    end
  end

  # call/2 issues requests to the server process
  def call(server_pid, request) do
    send(server_pid, {request, self()})

    receive do
      {:response, response} ->
        response
    end
  end
end

defmodule KVS do
  @moduledoc """
  Client process.

  ### Example usage:

    iex> pid = KVS.start
    #PID<0.196.0>

    iex> KVS.put(pid, :some_key, :some_value)
    :ok

    iex> KVS.get(pid, :some_key)
    :some_value
  """

  ## INTERFACE FUNCTIONS ##
  # clients use the interface functions to start and interact
  # with the process
  # interface functions run in client processes
  def start do
    ServerProcess.start(__MODULE__)
  end

  def put(pid, key, value) do
    ServerProcess.call(pid, {:put, key, value})
  end

  def get(pid, key) do
    ServerProcess.call(pid, {:get, key})
  end

  ## CALLBACK FUNCTIONS ##
  # used internally by the generic code
  # callback functions are always invoked in the server process
  def init, do: %{}

  @spec handle_call({:get, any} | {:put, any, any}, map) :: {any, map}
  def handle_call({:put, key, value}, state) do
    {:ok, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, state) do
    {Map.get(state, key), state}
  end
end
