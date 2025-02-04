defmodule LgbWeb.Components.Carousel do
  use Phoenix.LiveComponent
  alias Phoenix.LiveView.JS

  def mount(socket) do
    {:ok, assign(socket, current_index: 0, class: "")}
  end

  def render(assigns) do
    ~H"""
    <div
      id={"carousel-#{@id}"}
      class={[
        "relative w-full max-w-6xl mx-auto overflow-hidden shadow-md rounded-md group",
        @class
      ]}
    >
      <!-- Carousel Container -->
      <div
        class="relative h-96 flex space-x-4 transition-transform duration-500 ease-in-out"
        style={"transform: translateX(-#{@current_index * (100 / @length)}%)"}
      >
        <%= for uploaded_file <- @uploaded_files do %>
          <div class="flex-shrink-0 w-full" style={"width: #{100 / @length}%"}>
            <img
              src={
                Lgb.Profiles.ProfilePictureUploader.url(
                  {uploaded_file.image, uploaded_file},
                  :original,
                  signed: true
                )
              }
              alt="Carousel Image"
              class="w-full h-full object-cover rounded-lg"
            />
          </div>
        <% end %>
      </div>

      <div class="group">
        <!-- Previous Button -->
        <%= if @current_index > 0 and length(@uploaded_files) > 0 do %>
          <button
            phx-click={JS.push("prev", target: @myself)}
            class="absolute left-4 top-1/2 transform -translate-y-1/2 bg-white/30 hover:bg-purple-200 text-gray-800 rounded-full p-3 shadow-md transition-opacity duration-200 opacity-0 group-hover:opacity-100"
          >
            ←
          </button>
        <% end %>
        
    <!-- Next Button -->
        <%= if @current_index < length(@uploaded_files) - 1 and length(@uploaded_files) > 0 do %>
          <button
            phx-click={JS.push("next", target: @myself)}
            class="absolute right-4 top-1/2 transform -translate-y-1/2 bg-white/30 hover:bg-purple-200 text-gray-800 rounded-full p-3 shadow-md transition-opacity duration-200 opacity-0 group-hover:opacity-100"
          >
            →
          </button>
        <% end %>
      </div>
      
    <!-- Indicators -->
      <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
        <%= for {_uploaded_file, index} <- Enum.with_index(@uploaded_files) do %>
          <button class={"w-3 h-3 rounded-full #{if index == @current_index, do: "bg-colorSecondary", else: "bg-purple-200"} transition-colors duration-200 opacity-0 group-hover:opacity-100"}>
          </button>
        <% end %>
      </div>
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
end
