defmodule Shop1CmmsWeb.LoginLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <img class="mx-auto h-12 w-auto" src="/images/logo.svg" alt="Shop1 CMMS" />
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Sign in to CMMS
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Use your Shop1 FinishLine credentials
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <.form for={@form} phx-submit="login" class="space-y-6">
            <div>
              <label for="username" class="block text-sm font-medium text-gray-700">
                Username
              </label>
              <div class="mt-1">
                <input
                  id="username"
                  name="username"
                  type="text"
                  autocomplete="username"
                  required
                  class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                  value={@form[:username].value}
                />
              </div>
              <.error :for={msg <- @form[:username].errors}><%= msg %></.error>
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div class="mt-1">
                <input
                  id="password"
                  name="password"
                  type="password"
                  autocomplete="current-password"
                  required
                  class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                  value={@form[:password].value}
                />
              </div>
              <.error :for={msg <- @form[:password].errors}><%= msg %></.error>
            </div>

            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <input
                  id="remember_me"
                  name="remember_me"
                  type="checkbox"
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  checked={@form[:remember_me].value}
                />
                <label for="remember_me" class="ml-2 block text-sm text-gray-900">
                  Remember me
                </label>
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={@loading}
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <%= if @loading do %>
                  <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Signing in...
                <% else %>
                  Sign in
                <% end %>
              </button>
            </div>
          </.form>

          <%= if @error_message do %>
            <div class="mt-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative" role="alert">
              <span class="block sm:inline"><%= @error_message %></span>
            </div>
          <% end %>

          <div class="mt-6">
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-300" />
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-gray-500">
                  New to CMMS?
                </span>
              </div>
            </div>

            <div class="mt-4 text-center">
              <p class="text-sm text-gray-600">
                Contact your administrator to enable CMMS access for your Shop1 FinishLine account.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    # Redirect if already authenticated
    if session["user_id"] && session["tenant_id"] do
      {:ok, redirect(socket, to: ~p"/dashboard")}
    else
      {:ok,
       socket
       |> assign(:form, to_form(%{"username" => "", "password" => "", "remember_me" => false}))
       |> assign(:error_message, nil)
       |> assign(:loading, false)}
    end
  end

  @impl true
  def handle_event("login", %{"username" => username, "password" => password} = params, socket) do
    socket = assign(socket, :loading, true)

    case Auth.authenticate_user(username, password) do
      {:ok, user} ->
        # Get user's available tenants
        tenant_options = Auth.get_user_tenant_options(user)

        case tenant_options do
          [] ->
            {:noreply,
             socket
             |> assign(:loading, false)
             |> assign(:error_message, "No CMMS tenants available for your account. Contact your administrator.")}

          [single_tenant] ->
            # User has access to only one tenant, log them in directly
            {:noreply,
             socket
             |> put_flash(:info, "Welcome to Shop1 CMMS!")
             |> redirect(to: "/auth/login-complete?user_id=#{user.id}&tenant_id=#{single_tenant.id}&remember_me=#{params["remember_me"] || "false"}")}

          _multiple_tenants ->
            # User has multiple tenants, redirect to tenant selection
            {:noreply,
             socket
             |> put_flash(:info, "Please select your tenant.")
             |> redirect(to: "/auth/select-tenant?user_id=#{user.id}&remember_me=#{params["remember_me"] || "false"}")}
        end

      {:error, :cmms_not_enabled} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error_message, "CMMS access is not enabled for your account. Contact your administrator.")}

      {:error, :invalid_credentials} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error_message, "Invalid username or password.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error_message, "An error occurred during login. Please try again.")}
    end
  end
end
