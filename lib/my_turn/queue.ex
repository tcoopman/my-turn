defmodule MyTurn.Queue do
  use Agent

  alias Phoenix.PubSub

  def start_link([]) do
    Agent.start_link(fn -> %{queue: []} end, name: __MODULE__)
  end

  def join(key) do
    Agent.update(__MODULE__, fn state ->
      queue = [key | state.queue]
      %{state | queue: queue}
    end)

    PubSub.broadcast(MyTurn.PubSub, "queue", :queue_updated)
    :ok
  end

  def leave(key) do
    Agent.update(__MODULE__, fn state ->
      queue =
        Enum.reject(state.queue, fn
          ^key -> true
          _ -> false
        end)

      %{state | queue: queue}
    end)

    PubSub.broadcast(MyTurn.PubSub, "queue", :queue_updated)
    :ok
  end

  def state(key) do
    Agent.get(__MODULE__, fn %{queue: queue} ->
      index =
        queue
        |> Enum.reverse()
        |> Enum.find_index(fn
          ^key -> true
          _ -> false
        end)

      case index do
        nil -> {:error, :not_joined}
        i -> {:ok, i + 1}
      end
    end)
  end
end
