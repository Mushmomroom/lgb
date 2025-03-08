defmodule LgbWeb.Components.Carousel do
  use Phoenix.LiveComponent
  import LgbWeb.CoreComponents
  alias Phoenix.LiveView.JS

  def mount(socket) do
    {:ok, assign(socket, current_index: 0, class: "", current_user: nil)}
  end

  def render(assigns) do
    ~H"""
    <div
      id={"carousel-#{@id}"}
      class={["group relative mx-auto w-full max-w-6xl overflow-hidden rounded-md shadow-md", @class]}
    >
      <div
        class="relative flex h-96 space-x-4 transition-transform duration-500 ease-in-out"
        style={"transform: translateX(-#{@current_index * (100 / @length)}%)"}
      >
        <%= if length(@uploaded_files) > 0 do %>
          <div
            :for={uploaded_file <- @uploaded_files}
            class="group relative w-full flex-shrink-0"
            style={"width: #{100 / @length}%"}
          >
            <button
              :if={assigns.current_user}
              phx-click={JS.push("delete_profile_picture", target: @myself)}
              phx-value-profile-pic-id={uploaded_file.id}
              class="bg-white/75 absolute top-0 left-0 z-20 rounded-tl-lg rounded-br-lg opacity-0 transition-opacity duration-300 hover:bg-white group-hover:opacity-80"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 text-gray-700"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
            <img
              src={
                Lgb.Profiles.ProfilePictureUploader.url(
                  {uploaded_file.image, uploaded_file},
                  :original,
                  signed: true
                )
              }
              alt="Carousel Image"
              class="h-full w-full rounded-lg object-cover"
            />
          </div>
        <% else %>
          <div class="group relative w-full flex-shrink-0" style={"width: #{100 / @length}%"}>
            <div class="flex h-full w-full items-center justify-center rounded-lg bg-gray-200">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-32 w-32 text-gray-400"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
          </div>
        <% end %>
      </div>

      <div class="group">
        <!-- Previous Button -->
        <%= if @current_index > 0 and length(@uploaded_files) > 0 do %>
          <button
            phx-click={JS.push("prev", target: @myself)}
            class="bg-white/30 absolute top-1/2 left-4 -translate-y-1/2 transform rounded-full p-3 text-gray-800 opacity-0 shadow-md transition-opacity duration-200 hover:bg-purple-200 group-hover:opacity-100"
          >
            ←
          </button>
        <% end %>
        
    <!-- Next Button -->
        <%= if @current_index < length(@uploaded_files) - 1 and length(@uploaded_files) > 0 do %>
          <button
            phx-click={JS.push("next", target: @myself)}
            class="bg-white/30 absolute top-1/2 right-4 -translate-y-1/2 transform rounded-full p-3 text-gray-800 opacity-0 shadow-md transition-opacity duration-200 hover:bg-purple-200 group-hover:opacity-100"
          >
            →
          </button>
        <% end %>
      </div>
      
    <!-- Indicators -->
      <%= if length(@uploaded_files) > 0 do %>
        <div class="absolute bottom-4 left-1/2 flex -translate-x-1/2 transform space-x-2">
          <%= for {_uploaded_file, index} <- Enum.with_index(@uploaded_files) do %>
            <button class={"#{if index == @current_index, do: "bg-colorSecondary", else: "bg-purple-200"} h-3 w-3 rounded-full opacity-0 transition-colors duration-200 group-hover:opacity-100"}>
            </button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("next", _, socket) do
    current_index = rem(socket.assigns.current_index + 1, length(socket.assigns.uploaded_files))
    {:noreply, assign(socket, current_index: current_index)}
  end

  def handle_event("prev", _, socket) do
    current_index =
      rem(
        socket.assigns.current_index - 1 + length(socket.assigns.uploaded_files),
        length(socket.assigns.uploaded_files)
      )

    {:noreply, assign(socket, current_index: current_index)}
  end

  def handle_event("delete_profile_picture", %{"profile-pic-id" => id}, socket) do
    profile_picture = Lgb.Profiles.ProfilePicture.get!(id)

    case Lgb.Repo.delete(profile_picture) do
      {:ok, _} ->
        send(self(), :remove_profile_picture)
        {:noreply, socket}

      {:error, _} ->
        {:error, socket}
    end
  end
end
