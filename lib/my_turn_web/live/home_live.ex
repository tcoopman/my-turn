defmodule MyTurnWeb.HomeLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView

  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    <%= if !assigns[:key] do %>
    <.welcome />
    <% else %>
    <.app turn={@turn} queue={@queue} />
    <% end %>
    """
  end

  defp app(assigns) do
    ~H"""
    <div class="w-screen h-[100dvh] flex flex-col justify-between">
      <div class="h-full flex-grow flex flex-col gap-4 justify-center items-center">
        <span class="inline-block">
          Current turn: <%= @turn %>
        </span>
        <div>
          <ol>
            <li :for={{name, timestamp} <- @queue}><%= name %><%= waiting_time(DateTime.utc_now(), timestamp) %></li>
          </ol>
        </div>
      </div>
      <div class="h-40 flex gap-4 justify-center flex-shrink-0 items-center">
        <button
          class="rounded-full bg-sky-300 h-16 w-32 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-sky-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300/50 active:bg-sky-500"
          phx-click="queue"
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

  defp welcome(assigns) do
    ~H"""
    <div class="flex min-h-full flex-col justify-center px-6 py-12 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-sm">
        <h2 class="mt-10 text-center text-2xl font-bold leading-9 tracking-tight text-gray-900">
          Enter your name
        </h2>
      </div>

      <div class="mt-10 sm:mx-auto sm:w-full sm:max-w-sm">
        <.form class="space-y-6" phx-submit="join">
          <div>
            <label for="text" class="block text-sm font-medium leading-6 text-gray-900">Name</label>
            <div class="mt-2">
              <input
                id="name"
                name="name"
                type="name"
                required
                class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Join
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(MyTurn.PubSub, "queue")

      {:ok,
      assign(socket, turn: "not joined", queue: [])}
    else
      {:ok, assign(socket, turn: "not connected", queue: [])}
    end
  end

  def handle_event("join", %{"name" => name}, socket) do
    :ok = MyTurn.Queue.join(name)
    socket = assign(socket, key: name)

    {:noreply, update_turn_state(socket)}
  end

  def handle_event("queue", _, socket) do
    key = socket.assigns.key
    :ok = MyTurn.Queue.join(key)

    {:noreply, update_turn_state(socket)}
  end

  def handle_event("leave", _params, socket) do
    key = socket.assigns.key
    :ok = MyTurn.Queue.leave(key)

    {:noreply, update_turn_state(socket)}
  end

  def handle_info(:queue_updated, socket) do
    {:noreply, update_turn_state(socket)}
  end

  def terminate(_reson, socket) do
    key = socket.assigns.key
    :ok = MyTurn.Queue.leave(key)
    :ok
  end

  defp update_turn_state(socket) do
    key = socket.assigns.key
    assign(socket, MyTurn.Queue.state(key))
  end

  defp waiting_time(now, joined_time) do
    DateTime.diff(now, joined_time)
  end
end
