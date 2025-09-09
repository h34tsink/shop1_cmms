defmodule Shop1CmmsWeb.LoginLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="flex justify-center">
          <div class="w-16 h-16 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg">
            <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
            </svg>
          </div>
        </div>
        <h2 class="mt-6 text-center text-3xl font-bold text-gray-900">
          Welcome to Shop1 CMMS
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Comprehensive Maintenance Management System
        </p>
        <p class="mt-1 text-center text-xs text-gray-500">
          Sign in with your Shop1 FinishLine credentials
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow-xl sm:rounded-xl sm:px-10 border border-gray-100">
                    <.form
            for={@form}
            id="login-form"
            phx-submit="login"
            phx-change="validate"
            class="space-y-6"
          >
            <div>
              <label for="username" class="block text-sm font-semibold text-gray-700">
                Username
              </label>
              <div class="mt-2">
                <input
                  id="username"
                  name="username"
                  type="text"
                  autocomplete="username"
                  required
                  class={[
                    "appearance-none block w-full px-4 py-3 border rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all sm:text-sm",
                    if(@form[:username].errors != [], do: "border-red-300 focus:ring-red-500 focus:border-red-500", else: "border-gray-300")
                  ]}
                  placeholder="Enter your username"
                  value={@form[:username].value}
                />
              </div>
              <.error :for={msg <- @form[:username].errors}><%= msg %></.error>
            </div>

            <div>
              <label for="password" class="block text-sm font-semibold text-gray-700">
                Password
              </label>
              <div class="mt-2">
                <input
                  id="password"
                  name="password"
                  type="password"
                  autocomplete="current-password"
                  required
                  class={[
                    "appearance-none block w-full px-4 py-3 border rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all sm:text-sm",
                    if(@form[:password].errors != [], do: "border-red-300 focus:ring-red-500 focus:border-red-500", else: "border-gray-300")
                  ]}
                  placeholder="Enter your password"
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
                <label for="remember_me" class="ml-2 block text-sm text-gray-700">
                  Remember me for 30 days
                </label>
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={@loading}
                class="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-lg text-sm font-semibold text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transform transition-all duration-150 ease-in-out hover:scale-105 active:scale-95"
              >
                <%= if @loading do %>
                  <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Authenticating...
                <% else %>
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"></path>
                  </svg>
                  Sign in to CMMS
                <% end %>
              </button>
            </div>
          </.form>

          <%= if @error_message do %>
            <div class="mt-4 bg-red-50 border-l-4 border-red-400 p-4 rounded-r-lg" role="alert">
              <div class="flex">
                <div class="flex-shrink-0">
                  <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                  </svg>
                </div>
                <div class="ml-3">
                  <p class="text-sm text-red-700 font-medium">Authentication failed</p>
                  <p class="text-sm text-red-600"><%= @error_message %></p>
                </div>
              </div>
            </div>
          <% end %>

          <div class="mt-8">
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-200" />
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-3 bg-white text-gray-500 font-medium">
                  Need help accessing CMMS?
                </span>
              </div>
            </div>

            <div class="mt-6 text-center space-y-2">
              <p class="text-xs text-gray-500">
                Contact your system administrator for account access or<br/>
                visit the Shop1 FinishLine portal to manage your credentials
              </p>
              <div class="pt-4 border-t border-gray-100 mt-4">
                <p class="text-xs text-gray-400">
                  Shop1 CMMS • Comprehensive Maintenance Management
                </p>
              </div>
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
  def handle_event("validate", %{"username" => username, "password" => password} = params, socket) do
    form =
      %{"username" => username, "password" => password, "remember_me" => params["remember_me"] || false}
      |> to_form()
      |> Map.put(:errors, validate_login_form(username, password))

    # Clear server error when user starts typing
    error_message = if socket.assigns.error_message && (username != "" || password != ""), do: nil, else: socket.assigns.error_message

    {:noreply, socket |> assign(:form, form) |> assign(:error_message, error_message)}
  end

  @impl true
  def handle_event("login", %{"username" => username, "password" => password} = params, socket) do
    # Validate form first
    form_errors = validate_login_form(username, password)
    if form_errors != [] do
      form =
        %{"username" => username, "password" => password, "remember_me" => params["remember_me"] || false}
        |> to_form()
        |> Map.put(:errors, form_errors)

      {:noreply, assign(socket, :form, form)}
    else
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
      end
    end
  end

  defp validate_login_form(username, password) do
    errors = []

    errors = if String.trim(username) == "", do: [username: "Username is required"] ++ errors, else: errors
    errors = if String.trim(password) == "", do: [password: "Password is required"] ++ errors, else: errors

    errors
  end
end
