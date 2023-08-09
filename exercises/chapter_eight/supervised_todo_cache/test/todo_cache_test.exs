defmodule TodoCacheTest do
  use ExUnit.Case

  test "create a process that can be looked up by name" do
    {:ok, cache_pid} = Todo.Cache.start()
    process_pid = Todo.Cache.server_process(cache_pid, "one")

    assert process_pid != Todo.Cache.server_process(cache_pid, "two")
    assert process_pid == Todo.Cache.server_process(cache_pid, "one")
  end

  test "create a process that can have its state updated" do
    {:ok, cache_pid} = Todo.Cache.start()
    process_pid = Todo.Cache.server_process(cache_pid, "one")

    Todo.Server.add_entry(process_pid, %{date: "date-one", title: "title-one"})
    entries = Todo.Server.entries(process_pid)

    assert [%{date: "date-one", title: "title-one"}] = entries
  end
end
