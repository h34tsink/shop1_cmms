defmodule Shop1CmmsWeb.TenantSelectLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.{Auth, Accounts}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <img class="mx-auto h-12 w-auto" src="/images/logo.svg" alt="Shop1 CMMS" />
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Select Tenant
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Welcome, <%= @user.username %>! Choose your tenant to continue.
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <%= if @loading do %>
            <div class="text-center">
              <svg class="animate-spin mx-auto h-12 w-12 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <p class="mt-4 text-sm text-gray-600">Setting up your session...</p>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for tenant <- @tenant_options do %>
                <button
                  phx-click="select_tenant"
                  phx-value-tenant_id={tenant.id}
                  class="w-full text-left p-4 border border-gray-300 rounded-md hover:border-blue-500 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <h3 class="text-lg font-medium text-gray-900"><%= tenant.name %></h3>
                      <p class="text-sm text-gray-600">Code: <%= tenant.code %></p>
                      <p class="text-xs text-gray-500">Role: <%= String.replace(tenant.role, "_", " ") |> String.capitalize() %></p>
                    </div>
                    <svg class="h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                </button>
              <% end %>
            </div>

            <div class="mt-6 text-center">
              <button
                phx-click="logout"
                class="text-sm text-gray-600 hover:text-gray-900 underline"
              >
                Sign out and use different account
              </button>
            </div>
          <% end %>

          <%= if @error_message do %>
            <div class="mt-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative" role="alert">
              <span class="block sm:inline"><%= @error_message %></span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    user_id = params["user_id"]
    remember_me = params["remember_me"] == "true"

    if is_nil(user_id) do
      {:ok, redirect(socket, to: ~p"/login")}
    else
      case Accounts.get_user_with_details(user_id) do
        %{cmms_enabled: true} = user ->
          tenant_options = Auth.get_user_tenant_options(user)

          case tenant_options do
            [] ->
              {:ok,
               socket
               |> assign(:error_message, "No CMMS tenants available for your account.")
               |> assign(:user, user)
               |> assign(:tenant_options, [])
               |> assign(:remember_me, remember_me)
               |> assign(:loading, false)}

            [single_tenant] ->
              # Redirect immediately if only one tenant
              {:ok,
               redirect(socket, to: "/auth/login-complete?user_id=#{user.id}&tenant_id=#{single_tenant.id}&remember_me=#{remember_me}")}

            multiple_tenants ->
              {:ok,
               socket
               |> assign(:user, user)
               |> assign(:tenant_options, multiple_tenants)
               |> assign(:remember_me, remember_me)
               |> assign(:error_message, nil)
               |> assign(:loading, false)}
          end

        _ ->
          {:ok, redirect(socket, to: ~p"/login")}
      end
    end
  end

  @impl true
  def handle_event("select_tenant", %{"tenant_id" => tenant_id}, socket) do
    socket = assign(socket, :loading, true)

    case Auth.validate_tenant_access(socket.assigns.user, String.to_integer(tenant_id)) do
      {:ok, _user} ->
        {:noreply,
         redirect(socket, to: "/auth/login-complete?user_id=#{socket.assigns.user.id}&tenant_id=#{tenant_id}&remember_me=#{socket.assigns.remember_me}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error_message, "You don't have access to this tenant.")}
    end
  end

  def handle_event("logout", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end
end
