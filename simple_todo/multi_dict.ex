defmodule MultiDict do
  @moduledoc """
  """

  @type date() :: string()

  @spec new() :: map()
  def new(), do: %{}

  @spec add(map(), date(), string()) :: map()
  def add(dict, key, value) do
    Map.update(
      dict,
      key,
      [value],
      &[value | &1]
    )
  end

  @spec get(map(), date()) :: string() | []
  def get(dict, key) do
    Map.get(dict, key, [])
  end
end
