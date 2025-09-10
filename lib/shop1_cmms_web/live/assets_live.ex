defmodule Shop1CmmsWeb.AssetsLive do
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.Assets
  alias Shop1Cmms.Assets.{Asset, AssetType}

  def mount(_params, session, socket) do
    # Validate tenant access
    with {:ok, user} <- Shop1Cmms.Auth.require_authenticated_user(session),
         {:ok, _} <- Shop1Cmms.Auth.validate_tenant_access(user.id, session["tenant_id"]) do

      # Set user context for RLS
      Shop1Cmms.Accounts.set_user_tenant_context(user.id, session["tenant_id"])

      # Load assets and asset types
      assets = Assets.list_assets_with_details(session["tenant_id"])
      asset_types = Assets.list_asset_types(session["tenant_id"])

      socket = socket
      |> assign(:user, user)
      |> assign(:tenant_id, session["tenant_id"])
      |> assign(:assets, assets)
      |> assign(:asset_types, asset_types)
      |> assign(:selected_status, "all")
      |> assign(:selected_type, "all")
      |> assign(:search_term, "")
      |> assign(:page_title, "Assets Management")

      {:ok, socket}
    else
      {:error, :no_tenant_access} ->
        {:ok, redirect(socket, to: "/tenant-select")}
      {:error, :not_authenticated} ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    filtered_assets = filter_assets(socket.assigns.assets, status, socket.assigns.selected_type, socket.assigns.search_term)

    socket = socket
    |> assign(:selected_status, status)
    |> assign(:filtered_assets, filtered_assets)

    {:noreply, socket}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    filtered_assets = filter_assets(socket.assigns.assets, socket.assigns.selected_status, type, socket.assigns.search_term)

    socket = socket
    |> assign(:selected_type, type)
    |> assign(:filtered_assets, filtered_assets)

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    filtered_assets = filter_assets(socket.assigns.assets, socket.assigns.selected_status, socket.assigns.selected_type, term)

    socket = socket
    |> assign(:search_term, term)
    |> assign(:filtered_assets, filtered_assets)

    {:noreply, socket}
  end

  defp filter_assets(assets, status_filter, type_filter, search_term) do
    assets
    |> filter_by_status(status_filter)
    |> filter_by_type(type_filter)
    |> filter_by_search(search_term)
  end

  defp filter_by_status(assets, "all"), do: assets
  defp filter_by_status(assets, status) do
    Enum.filter(assets, &(&1.status == String.to_atom(status)))
  end

  defp filter_by_type(assets, "all"), do: assets
  defp filter_by_type(assets, type_id) do
    Enum.filter(assets, &(&1.asset_type_id == type_id))
  end

  defp filter_by_search(assets, ""), do: assets
  defp filter_by_search(assets, term) do
    term = String.downcase(term)
    Enum.filter(assets, fn asset ->
      String.contains?(String.downcase(asset.name || ""), term) ||
      String.contains?(String.downcase(asset.asset_number || ""), term) ||
      String.contains?(String.downcase(asset.manufacturer || ""), term)
    end)
  end

  defp status_color(status) do
    case status do
      :operational -> "bg-green-100 text-green-800"
      :maintenance -> "bg-yellow-100 text-yellow-800"
      :repair -> "bg-red-100 text-red-800"
      :retired -> "bg-gray-100 text-gray-800"
      :pending -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp criticality_color(criticality) do
    case criticality do
      :high -> "bg-red-100 text-red-800"
      :medium -> "bg-yellow-100 text-yellow-800"
      :low -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp format_currency(nil), do: "-"
  defp format_currency(amount) do
    Number.Currency.number_to_currency(amount)
  rescue
    _ -> "$#{amount}"
  end
end
