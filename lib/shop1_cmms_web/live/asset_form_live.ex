defmodule Shop1CmmsWeb.AssetFormLive do
  use Shop1CmmsWeb, :live_component

  alias Shop1Cmms.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full mx-auto bg-white rounded-lg shadow-md p-3">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-lg font-bold text-gray-900">
          <%= if @live_action == :new, do: "Add New Asset", else: "Edit Asset" %>
        </h2>
        <button
          phx-click="close_modal"
          phx-target={@myself}
          class="text-gray-400 hover:text-gray-600"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>

      <.form
        for={@form}
        id="asset-form-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-3"
      >
        <!-- Basic Information -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          <div>
            <.input field={@form[:name]} type="text" label="Asset Name" required />
          </div>
          <div>
            <.input field={@form[:asset_number]} type="text" label="Asset Number" required />
          </div>
          <div>
            <.input
              field={@form[:asset_type_id]}
              type="select"
              label="Asset Type"
              options={asset_type_options(@asset_types)}
              prompt="Select Asset Type"
              required
            />
          </div>
          <div>
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={[
                {"Operational", :operational},
                {"Maintenance", :maintenance},
                {"Repair", :repair},
                {"Retired", :retired},
                {"Disposed", :disposed}
              ]}
              required
            />
          </div>
        </div>

        <!-- Physical Details -->
        <div class="border-t pt-3">
          <h3 class="text-base font-semibold text-gray-900 mb-2">Physical Details</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
            <div>
              <.input field={@form[:manufacturer]} type="text" label="Manufacturer" />
            </div>
            <div>
              <.input field={@form[:model]} type="text" label="Model" />
            </div>
            <div>
              <.input field={@form[:serial_number]} type="text" label="Serial Number" />
            </div>
            <div>
              <.input
                field={@form[:location_id]}
                type="select"
                label="Location"
                options={asset_location_options(@asset_locations)}
                prompt="Select Location"
              />
            </div>
            <div>
              <.input
                field={@form[:criticality]}
                type="select"
                label="Criticality"
                options={[
                  {"Low", :low},
                  {"Medium", :medium},
                  {"High", :high},
                  {"Critical", :critical}
                ]}
                required
              />
            </div>
          </div>
        </div>

        <!-- Dates & Financial Information -->
        <div class="border-t pt-3">
          <h3 class="text-base font-semibold text-gray-900 mb-2">Dates & Financial Information</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            <div>
              <.input field={@form[:purchase_date]} type="date" label="Purchase Date" />
            </div>
            <div>
              <.input field={@form[:install_date]} type="date" label="Install Date" />
            </div>
            <div>
              <.input
                field={@form[:purchase_cost]}
                type="number"
                label="Purchase Cost"
                step="0.01"
              />
            </div>
            <div>
              <.input field={@form[:warranty_expiry]} type="date" label="Warranty Expiry" />
            </div>
          </div>
        </div>

        <!-- Description -->
        <div>
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            rows="2"
          />
        </div>

        <!-- Form Actions -->
        <div class="flex justify-end space-x-2 pt-3 border-t">
          <button
            type="button"
            phx-click="close_modal"
            phx-target={@myself}
            class="px-2 py-1 text-xs font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Cancel
          </button>
          <button
            type="submit"
            phx-disable-with="Saving..."
            class="px-2 py-1 text-xs font-medium text-white bg-blue-600 border border-transparent rounded-md shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
          >
            <%= if @live_action == :new, do: "Create Asset", else: "Update Asset" %>
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{asset: asset} = assigns, socket) do
    changeset = Assets.change_asset(asset)

    socket = socket
    |> assign(assigns)
    |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset =
      socket.assigns.asset
      |> Assets.change_asset(asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.live_action, asset_params)
  end

  def handle_event("close_modal", _params, socket) do
    send(self(), {:close_modal})
    {:noreply, socket}
  end

  defp save_asset(socket, :new, asset_params) do
    asset_params = Map.put(asset_params, "tenant_id", socket.assigns.tenant_id)

    case Assets.create_asset(asset_params) do
      {:ok, asset} ->
        send(self(), {:asset_saved, asset, "Asset created successfully"})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset(socket, :edit, asset_params) do
    case Assets.update_asset(socket.assigns.asset, asset_params) do
      {:ok, asset} ->
        send(self(), {:asset_saved, asset, "Asset updated successfully"})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp asset_type_options(asset_types) do
    Enum.map(asset_types, &{&1.name, &1.id})
  end

  defp asset_location_options(asset_locations) do
    Enum.map(asset_locations, &{&1.name, &1.id})
  end
end
