defmodule Shop1CmmsWeb.UserAuth do
  @moduledoc """
  Authentication plug and helpers for CMMS LiveView and controllers.
  Integrates with existing Shop1FinishLine authentication system.
  """

  use Shop1CmmsWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Shop1Cmms.{Auth, Accounts}

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_shop1_cmms_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in by storing the user ID and tenant ID in the session.
  """
  def log_in_user(conn, user, tenant_id, params \\ %{}) do
    token = :crypto.strong_rand_bytes(32) |> Base.encode64()
    
    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
    |> put_session(:tenant_id, tenant_id)
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{user.id}")
    |> maybe_write_remember_me_cookie(user.id, params)
    |> establish_session_context(user.id, tenant_id)
  end

  defp maybe_write_remember_me_cookie(conn, user_id, %{"remember_me" => "true"}) do
    token = :crypto.strong_rand_bytes(32) |> Base.encode64()
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _user_id, _params) do
    conn
  end

  defp establish_session_context(conn, user_id, tenant_id) do
    case Auth.establish_session_context(user_id, tenant_id) do
      {:ok, _user} -> conn
      {:error, _reason} -> 
        conn
        |> clear_session()
        |> put_flash(:error, "Unable to establish session context.")
    end
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out by clearing session and database context.
  """
  def log_out_user(conn) do
    user_id = get_session(conn, :user_id)
    
    if user_id do
      case Accounts.get_user_with_details(user_id) do
        %{} = user -> Auth.logout(user)
        _ -> :ok
      end
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
  end

  @doc """
  Authenticates the user by looking into the session.
  """
  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    tenant_id = get_session(conn, :tenant_id)
    
    cond do
      is_nil(user_id) ->
        assign(conn, :current_user, nil)
      
      is_nil(tenant_id) ->
        assign(conn, :current_user, nil)
      
      true ->
        case Accounts.get_user_with_details(user_id) do
          %{cmms_enabled: true} = user ->
            case Auth.validate_tenant_access(user, tenant_id) do
              {:ok, _} ->
                # Re-establish context for this request
                Auth.establish_session_context(user_id, tenant_id)
                
                conn
                |> assign(:current_user, user)
                |> assign(:current_tenant_id, tenant_id)
              
              {:error, _} ->
                assign(conn, :current_user, nil)
            end
          
          _ ->
            assign(conn, :current_user, nil)
        end
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user and current_tenant_id
      to socket assigns based on user_id and tenant_id in session, but does not redirect if missing.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and if successful, assigns current_user and current_tenant_id to socket assigns.
      If the user is not authenticated, redirects to the login page.

    * `:ensure_tenant_access` - Ensures the user has access to the current tenant.
      If not, redirects to tenant selection page.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      If the user is authenticated, redirects to the signed_in path.

  ## Examples

  Use the `on_mount` lifecycle in LiveViews to mount or authenticate
  the current_user:

      defmodule Shop1CmmsWeb.PageLive do
        use Shop1CmmsWeb, :live_view

        on_mount {Shop1CmmsWeb.UserAuth, :mount_current_user}

        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{Shop1CmmsWeb.UserAuth, :ensure_authenticated}] do
        live "/dashboard", DashboardLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  def on_mount(:ensure_tenant_access, params, session, socket) do
    socket = mount_current_user(socket, session)
    tenant_id = socket.assigns[:current_tenant_id]

    case {socket.assigns.current_user, tenant_id} do
      {%{} = user, tenant_id} when not is_nil(tenant_id) ->
        case Auth.validate_tenant_access(user, tenant_id) do
          {:ok, _} -> {:cont, socket}
          {:error, _} ->
            socket =
              socket
              |> Phoenix.LiveView.put_flash(:error, "You don't have access to this tenant.")
              |> Phoenix.LiveView.redirect(to: ~p"/select-tenant")

            {:halt, socket}
        end

      _ ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You must select a tenant to access this page.")
          |> Phoenix.LiveView.redirect(to: ~p"/select-tenant")

        {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    user_id = session["user_id"]
    tenant_id = session["tenant_id"]

    case {user_id, tenant_id} do
      {user_id, tenant_id} when not is_nil(user_id) and not is_nil(tenant_id) ->
        case Accounts.get_user_with_details(user_id) do
          %{cmms_enabled: true} = user ->
            case Auth.validate_tenant_access(user, tenant_id) do
              {:ok, _} ->
                # Re-establish context for this LiveView
                Auth.establish_session_context(user_id, tenant_id)
                
                socket
                |> Phoenix.Component.assign(:current_user, user)
                |> Phoenix.Component.assign(:current_tenant_id, tenant_id)
              
              {:error, _} ->
                Phoenix.Component.assign(socket, :current_user, nil)
            end
          
          _ ->
            Phoenix.Component.assign(socket, :current_user, nil)
        end

      _ ->
        Phoenix.Component.assign(socket, :current_user, nil)
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  @doc """
  Used for routes that require tenant access.
  """
  def require_tenant_access(conn, _opts) do
    user = conn.assigns[:current_user]
    tenant_id = conn.assigns[:current_tenant_id]

    case {user, tenant_id} do
      {%{} = user, tenant_id} when not is_nil(tenant_id) ->
        case Auth.validate_tenant_access(user, tenant_id) do
          {:ok, _} -> conn
          {:error, _} ->
            conn
            |> put_flash(:error, "You don't have access to this tenant.")
            |> redirect(to: ~p"/select-tenant")
            |> halt()
        end

      _ ->
        conn
        |> put_flash(:error, "You must select a tenant to access this page.")
        |> redirect(to: ~p"/select-tenant")
        |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/dashboard"

  @doc """
  Authorization helper for controllers and LiveViews.
  """
  def authorize(conn_or_socket, action, resource \\ nil) do
    user = conn_or_socket.assigns[:current_user]
    tenant_id = conn_or_socket.assigns[:current_tenant_id]

    case Auth.authorize(user, action, resource, tenant_id) do
      :ok -> :ok
      {:error, :unauthorized} -> {:error, :unauthorized}
    end
  end

  @doc """
  Check if user is authorized (returns boolean).
  """
  def authorized?(conn_or_socket, action, resource \\ nil) do
    case authorize(conn_or_socket, action, resource) do
      :ok -> true
      _ -> false
    end
  end
end
