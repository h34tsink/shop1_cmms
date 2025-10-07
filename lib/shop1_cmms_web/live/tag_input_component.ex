defmodule Shop1CmmsWeb.TagInputComponent do
  use Shop1CmmsWeb, :live_component
  alias Shop1Cmms.Metadata

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:suggestions, [])
     |> assign(:show_suggestions, false)
     |> assign(:input_value, "")
     |> assign(:selected_index, 0)}
  end

  @impl true
  def update(assigns, socket) do
    # tags: list of current tag strings
    # tag_type: :skill, :tool, or :ppe
    # field_name: form field name
    # tenant_id: current tenant
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tags, assigns[:tags] || [])
     |> assign(:tag_type, assigns[:tag_type])
     |> assign(:label, assigns[:label])
     |> assign(:field_name, assigns[:field_name])
     |> assign(:placeholder, assigns[:placeholder] || "Type to add tags (comma-separated)")
     |> assign_new(:input_value, fn -> "" end)
     |> assign_new(:suggestions, fn -> [] end)
     |> assign_new(:show_suggestions, fn -> false end)}
  end

  @impl true
  def handle_event("input_change", %{"value" => value}, socket) when is_binary(value) do
    handle_input_change(value, socket)
  end

  # Handle phx-keyup event format (comes from input element)
  def handle_event("input_change", %{"key" => _key, "value" => value}, socket) do
    handle_input_change(value, socket)
  end

  # Fallback for other event formats
  def handle_event("input_change", _params, socket) do
    {:noreply, socket}
  end

  defp handle_input_change(value, socket) do
    # Get suggestions based on input - show after 1 character
    suggestions = if String.length(value) >= 1 do
      tenant_id = socket.assigns.tenant_id
      tag_type = socket.assigns.tag_type
      
      Metadata.list_pm_tags(tenant_id, type: tag_type, search: value, active_only: true)
      |> Enum.take(10)
      |> Enum.map(& &1.name)
    else
      []
    end

    {:noreply,
     socket
     |> assign(:input_value, value)
     |> assign(:suggestions, suggestions)
     |> assign(:show_suggestions, length(suggestions) > 0)
     |> assign(:selected_index, 0)}
  end

  @impl true
  def handle_event("add_tags", %{"value" => value}, socket) when is_binary(value) do
    add_tags_from_value(value, socket)
  end

  # Handle blur event which might not have value param
  def handle_event("add_tags", _params, socket) do
    add_tags_from_value(socket.assigns.input_value, socket)
  end

  defp add_tags_from_value(value, socket) do
    new_tags = value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    
    current_tags = socket.assigns.tags
    updated_tags = (current_tags ++ new_tags) |> Enum.uniq()
    
    # Only notify if there are actual changes
    if updated_tags != current_tags and length(new_tags) > 0 do
      send(self(), {:tags_updated, socket.assigns.field_name, updated_tags})
    end
    
    {:noreply,
     socket
     |> assign(:tags, updated_tags)
     |> assign(:input_value, "")
     |> assign(:suggestions, [])
     |> assign(:show_suggestions, false)}
  end

  @impl true
  def handle_event("select_suggestion", %{"tag" => tag}, socket) do
    current_tags = socket.assigns.tags
    updated_tags = (current_tags ++ [tag]) |> Enum.uniq()
    
    send(self(), {:tags_updated, socket.assigns.field_name, updated_tags})
    
    {:noreply,
     socket
     |> assign(:tags, updated_tags)
     |> assign(:input_value, "")
     |> assign(:suggestions, [])
     |> assign(:show_suggestions, false)}
  end

  @impl true
  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    updated_tags = Enum.reject(socket.assigns.tags, &(&1 == tag))
    
    send(self(), {:tags_updated, socket.assigns.field_name, updated_tags})
    
    {:noreply, assign(socket, :tags, updated_tags)}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    handle_event("add_tags", %{"value" => socket.assigns.input_value}, socket)
  end

  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply,
     socket
     |> assign(:show_suggestions, false)
     |> assign(:selected_index, 0)}
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="tag-input-component">
      <label class="block text-xs font-medium text-gray-700 mb-1">
        <%= @label %>
      </label>
      
      <!-- Selected Tags Display -->
      <div class="flex flex-wrap gap-1 mb-2">
        <%= for tag <- @tags do %>
          <span class={tag_badge_class(@tag_type)}>
            <%= tag %>
            <button
              type="button"
              phx-click="remove_tag"
              phx-value-tag={tag}
              phx-target={@myself}
              class="ml-1 hover:text-red-700"
            >
              ×
            </button>
          </span>
        <% end %>
      </div>
      
      <!-- Input with Autocomplete -->
      <div class="relative">
        <input
          type="text"
          value={@input_value}
          phx-keyup="input_change"
          phx-debounce="300"
          phx-blur="add_tags"
          phx-keydown="keydown"
          phx-target={@myself}
          placeholder={@placeholder}
          autocomplete="off"
          class="w-full text-sm border-2 border-gray-300 rounded px-3 py-2 focus:border-blue-500 focus:ring-0"
        />
        
        <!-- Suggestions Dropdown -->
        <%= if @show_suggestions and length(@suggestions) > 0 do %>
          <div class="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-48 overflow-y-auto">
            <%= for {suggestion, idx} <- Enum.with_index(@suggestions) do %>
              <button
                type="button"
                phx-click="select_suggestion"
                phx-value-tag={suggestion}
                phx-target={@myself}
                class={"px-3 py-2 text-sm text-left w-full hover:bg-blue-50 #{if idx == @selected_index, do: "bg-blue-100", else: ""}"}
              >
                <%= suggestion %>
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
      
      <p class="mt-1 text-xs text-gray-500">
        Type and press Enter, or separate multiple tags with commas
      </p>
      
      <!-- Hidden input to store tags for form submission -->
      <input type="hidden" name={@field_name} value={Enum.join(@tags, ",")} />
    </div>
    """
  end

  defp tag_badge_class(:skill), do: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800"
  defp tag_badge_class(:tool), do: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800"
  defp tag_badge_class(:ppe), do: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800"
  defp tag_badge_class(_), do: "inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800"
end
