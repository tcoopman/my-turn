defmodule MyTurnWeb.HomeLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView

  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    <div class="w-screen h-[100dvh] flex flex-col justify-between">
      <div class="h-full flex-grow flex justify-center items-center">
        Current turn: <%= @turn %>
      </div>
      <div class="h-40 flex gap-4 justify-center flex-shrink-0 items-center">
        <button
          class="rounded-full bg-sky-300 h-16 w-32 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
          phx-click="join"
        >
          Queue
        </button>
        <button
          class="rounded-full bg-sky-300  h-16 w-32 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
          phx-click="leave"
        >
          Leave
        </button>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      key = Uniq.UUID.uuid7()
      PubSub.subscribe(MyTurn.PubSub, "queue")

      {:ok,
       assign(socket, %{
         key: key,
         turn: turn(key)
       })}
    else
      {:ok, assign(socket, :turn, "not connected")}
    end
  end

  def handle_event("join", _params, socket) do
    key = socket.assigns.key
    :ok = MyTurn.Queue.join(key)

    {:noreply, assign(socket, :turn, turn(key))}
  end

  def handle_event("leave", _params, socket) do
    key = socket.assigns.key
    :ok = MyTurn.Queue.leave(key)

    {:noreply, assign(socket, :turn, turn(key))}
  end

  def handle_info(:queue_updated, socket) do
    key = socket.assigns.key

    {:noreply, assign(socket, :turn, turn(key))}
  end

  def terminate(_reson, socket) do
    key = socket.assigns.key
    :ok = MyTurn.Queue.leave(key)
    :ok
  end

  defp turn(key) do
    with {:ok, turn} <- MyTurn.Queue.state(key) do
      turn
    else
      _ -> "not joined"
    end
  end
end
