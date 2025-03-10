defmodule LgbWeb.ProfileLive.Show do
  use LgbWeb, :live_view
  alias Lgb.Chatting
  alias Lgb.Profiles

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    current_profile = Lgb.Accounts.User.current_profile(user)

    profile =
      Profiles.get_profile!(id)
      |> Lgb.Repo.preload([:user, :first_picture, :dating_goals, :hobbies])

    selected_attributes = profile.dating_goals
    selected_hobbies = profile.hobbies

    Lgb.ProfileViews.create_or_update_profile_view(%{
      viewer_id: current_profile.id,
      viewed_profile_id: profile.id,
      last_viewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    {:noreply,
     socket
     |> assign(:profile, profile)
     |> assign(:dating_goals, selected_attributes)
     |> assign(:current_index, 0)
     |> assign(:length, 3)
     |> assign(:hobbies, selected_hobbies)
     |> assign(:distance, Lgb.Profiles.calculate_distance(profile, current_profile))
     |> assign(:uploaded_files, Profiles.list_profile_pictures(profile))}
  end

  @impl true
  def handle_event("message", %{"id" => other_profile_id}, socket) do
    user = socket.assigns.current_user
    profile = Lgb.Accounts.User.current_profile(user)
    other_profile = Profiles.get_profile!(other_profile_id)

    case Chatting.get_or_create_conversation(profile, other_profile) do
      {:ok, conversation} ->
        {:noreply, push_navigate(socket, to: ~p"/conversations/#{conversation.uuid}")}

      {:error, _} ->
        {:noreply, socket}
    end
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
