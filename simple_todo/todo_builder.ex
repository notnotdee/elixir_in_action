defmodule TodoList do
  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %__MODULE__{},
      # &2 is the accumulator and &1 is the entry
      &add_entry(&2, &1)
    )
  end
end
