defmodule Shop1CmmsWeb.AssetsLive do
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.Assets
  alias Shop1Cmms.Assets.{Asset, AssetType}
  import Shop1CmmsWeb.Components.Assets

  def mount(%{"id" => id}, _session, socket) when socket.assigns.live_action == :edit do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    asset = Assets.get_asset!(id, current_tenant_id)
    asset_types = Assets.list_asset_types(current_tenant_id)

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:asset, asset)
    |> assign(:asset_types, asset_types)
    |> assign(:page_title, "Edit Asset - #{asset.name}")
    |> assign(:live_action, :edit)
    |> assign(:show_modal, true)

    {:ok, socket}
  end

  def mount(_params, _session, socket) when socket.assigns.live_action == :new do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    # Load assets and asset types
    assets = Assets.list_assets_with_details(current_tenant_id)
    asset_types = Assets.list_asset_types(current_tenant_id)

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:assets, assets)
    |> assign(:asset_types, asset_types)
    |> assign(:asset, %Assets.Asset{})
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> assign(:show_advanced_filters, false)
    |> assign(:filtered_assets, assets)
    |> assign(:page_title, "Add New Asset")
    |> assign(:view_mode, "grid")
    |> assign(:live_action, :new)
    |> assign(:show_modal, true)

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    # Load assets and asset types
    assets = Assets.list_assets_with_details(current_tenant_id)
    asset_types = Assets.list_asset_types(current_tenant_id)

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:assets, assets)
    |> assign(:asset_types, asset_types)
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> assign(:show_advanced_filters, false)
    |> assign(:filtered_assets, assets)
    |> assign(:page_title, "Assets Management")
    |> assign(:view_mode, "grid")  # grid, list, kanban
    |> assign(:live_action, :index)
    |> assign(:show_modal, false)

    {:ok, socket}
  end



  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    socket = socket
    |> assign(:search_term, term)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view_mode, view)}
  end

  def handle_event("toggle_advanced_filters", _params, socket) do
    {:noreply, assign(socket, :show_advanced_filters, !socket.assigns.show_advanced_filters)}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    socket = socket
    |> assign(:selected_status, status)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    socket = socket
    |> assign(:selected_type, type)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_criticality", %{"criticality" => criticality}, socket) do
    socket = socket
    |> assign(:selected_criticality, criticality)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_manufacturer", %{"manufacturer" => manufacturer}, socket) do
    socket = socket
    |> assign(:selected_manufacturer, manufacturer)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_date_range", %{"date_from" => date_from, "date_to" => date_to}, socket) do
    socket = socket
    |> assign(:date_from, date_from)
    |> assign(:date_to, date_to)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket = socket
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("delete_asset", %{"id" => id}, socket) do
    asset = Assets.get_asset!(id, socket.assigns.tenant_id)

    case Assets.delete_asset(asset) do
      {:ok, _asset} ->
        assets = Assets.list_assets_with_details(socket.assigns.tenant_id)
        socket = socket
        |> assign(:assets, assets)
        |> apply_filters()
        |> put_flash(:info, "Asset deleted successfully")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete asset. It may have associated work orders.")}
    end
  end

  @impl true
  def handle_info({:close_modal}, socket) do
    {:noreply, push_patch(socket, to: ~p"/assets")}
  end

  def handle_info({:asset_saved, _asset, message}, socket) do
    assets = Assets.list_assets_with_details(socket.assigns.tenant_id)

    socket = socket
    |> assign(:assets, assets)
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> apply_filters()
    |> put_flash(:info, message)
    |> push_patch(to: ~p"/assets")

    {:noreply, socket}
  end

  defp apply_filters(socket) do
    filtered_assets = socket.assigns.assets
    |> filter_by_status(socket.assigns.selected_status)
    |> filter_by_type(socket.assigns.selected_type)
    |> filter_by_criticality(socket.assigns.selected_criticality)
    |> filter_by_manufacturer(socket.assigns.selected_manufacturer)
    |> filter_by_search(socket.assigns.search_term)
    |> filter_by_date_range(socket.assigns.date_from, socket.assigns.date_to)

    assign(socket, :filtered_assets, filtered_assets)
  end

  defp filter_by_status(assets, "all"), do: assets
  defp filter_by_status(assets, status) do
    Enum.filter(assets, &(&1.status == String.to_atom(status)))
  end

  defp filter_by_type(assets, "all"), do: assets
  defp filter_by_type(assets, type_id) when is_binary(type_id) do
    {type_id_int, _} = Integer.parse(type_id)
    Enum.filter(assets, &(&1.asset_type_id == type_id_int))
  end
  defp filter_by_type(assets, type_id) do
    Enum.filter(assets, &(&1.asset_type_id == type_id))
  end

  defp filter_by_criticality(assets, "all"), do: assets
  defp filter_by_criticality(assets, criticality) do
    Enum.filter(assets, &(&1.criticality == String.to_atom(criticality)))
  end

  defp filter_by_manufacturer(assets, "all"), do: assets
  defp filter_by_manufacturer(assets, ""), do: assets
  defp filter_by_manufacturer(assets, manufacturer) do
    Enum.filter(assets, fn asset ->
      asset.manufacturer && String.downcase(asset.manufacturer) == String.downcase(manufacturer)
    end)
  end

  defp filter_by_search(assets, ""), do: assets
  defp filter_by_search(assets, term) do
    term = String.downcase(term)
    Enum.filter(assets, fn asset ->
      String.contains?(String.downcase(asset.name || ""), term) ||
      String.contains?(String.downcase(asset.asset_number || ""), term) ||
      String.contains?(String.downcase(asset.manufacturer || ""), term) ||
      String.contains?(String.downcase(asset.model || ""), term) ||
      (asset.location && String.contains?(String.downcase(asset.location.name || ""), term))
    end)
  end

  defp filter_by_date_range(assets, "", ""), do: assets
  defp filter_by_date_range(assets, date_from, date_to) do
    {from_date, to_date} = parse_date_range(date_from, date_to)

    Enum.filter(assets, fn asset ->
      case asset.install_date do
        nil -> false
        date ->
          (from_date == nil || Date.compare(date, from_date) != :lt) &&
          (to_date == nil || Date.compare(date, to_date) != :gt)
      end
    end)
  end

  defp parse_date_range(date_from, date_to) do
    from_date = if date_from != "", do: Date.from_iso8601!(date_from), else: nil
    to_date = if date_to != "", do: Date.from_iso8601!(date_to), else: nil
    {from_date, to_date}
  end

  defp get_unique_manufacturers(assets) do
    assets
    |> Enum.map(& &1.manufacturer)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end


end
