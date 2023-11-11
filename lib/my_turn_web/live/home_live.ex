defmodule MyTurnWeb.HomeLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 w-screen h-screen flex flex-col justify-between">
      <div class="h-full flex-grow flex justify-center items-center">
        Current turn: <%= @turn %>
      </div>
      <div class="h-20 flex gap-4 justify-center flex-shrink-0 items-center">
        <button
          class="rounded-full bg-sky-300 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
          phx-click="join"
        >
          Queue
        </button>
        <button
          class="rounded-full bg-sky-300 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
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

  defp turn(key) do
    with {:ok, turn} <- MyTurn.Queue.state(key) do
      turn
    else
      _ -> "not joined"
    end
  end
end
