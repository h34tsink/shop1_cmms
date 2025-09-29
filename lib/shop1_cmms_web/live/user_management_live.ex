defmodule Shop1CmmsWeb.UserManagementLive do
  use Shop1CmmsWeb, :live_view
  import Phoenix.HTML.Form

  alias Shop1Cmms.{Accounts, Tenants}
  alias Shop1Cmms.Accounts.{User, UserTenantAssignment}

  @impl true
  def mount(_params, _session, socket) do
    # Require admin permissions for user management
    if socket.assigns.current_user && can_manage_users?(socket.assigns.current_user) do
      socket =
        socket
        |> assign(:page_title, "User Management")
        |> assign(:users, [])
        |> assign(:search_term, "")
        |> assign(:selected_role, "all")
        |> assign(:loading, true)
        |> assign(:role_options, load_role_options())
        |> assign(:role_select_options, load_role_select_options())
        |> assign(:pending_role_changes, %{})
        |> load_users()

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You don't have permission to access this page.")
       |> redirect(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    case socket.assigns.live_action do
      :index ->
        {:noreply, socket}
      :new ->
        changeset = User.registration_changeset(%User{}, %{})
        socket = socket
          |> assign(:page_title, "Add New User")
          |> assign(:user, %User{})
          |> assign(:form, to_form(changeset))
        {:noreply, socket}
      :edit ->
        user = Accounts.get_user!(params["id"])
        changeset = Accounts.change_user(user)
        socket = socket
          |> assign(:page_title, "Edit User: #{user.username}")
          |> assign(:user, user)
          |> assign(:form, to_form(changeset))
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    socket =
      socket
      |> assign(:search_term, term)
      |> load_users()

    {:noreply, socket}
  end

  def handle_event("filter_role", %{"role" => role}, socket) do
    socket =
      socket
      |> assign(:selected_role, role)
      |> load_users()

    {:noreply, socket}
  end

  def handle_event("enable_cmms", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    case Accounts.enable_cmms_for_user(user_id, current_tenant_id, current_user.id) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "CMMS access enabled for user")
          |> load_users()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to enable CMMS access")}
    end
  end

  def handle_event("disable_cmms", %{"user_id" => user_id}, socket) do
    case Accounts.disable_cmms_for_user(user_id) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "CMMS access disabled for user")
          |> load_users()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to disable CMMS access")}
    end
  end

  def handle_event("change_role", %{"user_id" => user_id, "role" => new_role}, socket) do
    user_id_int = String.to_integer(user_id)
    new_role_int = String.to_integer(new_role)

    # Update pending changes
    pending_changes = Map.put(socket.assigns.pending_role_changes, user_id_int, new_role_int)

    {:noreply, assign(socket, :pending_role_changes, pending_changes)}
  end

  def handle_event("save_role_change", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id
    user_id_int = String.to_integer(user_id)

    case Map.get(socket.assigns.pending_role_changes, user_id_int) do
      nil ->
        {:noreply, socket}
      new_role ->
        case Accounts.update_user_role(user_id_int, current_tenant_id, new_role, current_user.id) do
          {:ok, _assignment} ->
            # Remove from pending changes and reload users
            pending_changes = Map.delete(socket.assigns.pending_role_changes, user_id_int)
            socket =
              socket
              |> assign(:pending_role_changes, pending_changes)
              |> put_flash(:info, "User role updated successfully")
              |> load_users()

            {:noreply, socket}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to update user role")}
        end
    end
  end

  def handle_event("cancel_role_change", %{"user_id" => user_id}, socket) do
    user_id_int = String.to_integer(user_id)
    pending_changes = Map.delete(socket.assigns.pending_role_changes, user_id_int)

    {:noreply, assign(socket, :pending_role_changes, pending_changes)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = case socket.assigns.live_action do
      :new ->
        %User{}
        |> User.registration_changeset(user_params)
        |> Map.put(:action, :validate)
      :edit ->
        socket.assigns.user
        |> Accounts.change_user(user_params)
        |> Map.put(:action, :validate)
    end

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.live_action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        socket =
          socket
          |> put_flash(:info, "User updated successfully")
          |> push_navigate(to: ~p"/admin/users")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    case Accounts.create_user_with_password(user_params) do
      {:ok, user} ->
        # Create tenant assignment if role is selected
        case user_params["role_id"] do
          nil ->
            socket =
              socket
              |> put_flash(:info, "User created successfully. Please assign a role.")
              |> push_navigate(to: ~p"/admin/users")
            {:noreply, socket}
          role_id when is_binary(role_id) and role_id != "" ->
            # Create tenant assignment with selected role
            case Accounts.create_user_tenant_assignment(%{
              user_id: user.id,
              tenant_id: current_tenant_id,
              role_id: String.to_integer(role_id),
              granted_by: current_user.id,
              is_active: true
            }) do
              {:ok, _assignment} ->
                socket =
                  socket
                  |> put_flash(:info, "User created and assigned role successfully")
                  |> push_navigate(to: ~p"/admin/users")
                {:noreply, socket}
              {:error, _reason} ->
                {:noreply, put_flash(socket, :warning, "User created but failed to assign role")}
            end
          _ ->
            socket =
              socket
              |> put_flash(:info, "User created successfully")
              |> push_navigate(to: ~p"/admin/users")
            {:noreply, socket}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp load_users(socket) do
    current_tenant_id = socket.assigns.current_tenant_id
    search_term = socket.assigns[:search_term] || ""
    selected_role = socket.assigns[:selected_role] || "all"

    users = get_tenant_users(current_tenant_id, search_term, selected_role)

    # Precompute role selection data to avoid complex template logic
    enriched_users = Enum.map(users, fn user ->
      current_role_id = case user.user_tenant_assignments do
        [assignment | _] -> assignment.role_id
        _ -> nil
      end

      pending_role_id = Map.get(socket.assigns.pending_role_changes, user.id, current_role_id)

      Map.put(user, :display_role_data, %{
        current_role_id: current_role_id,
        selected_role_id: pending_role_id,
        has_pending_change: Map.has_key?(socket.assigns.pending_role_changes, user.id)
      })
    end)

    socket
    |> assign(:users, enriched_users)
    |> assign(:loading, false)
  end

  defp get_tenant_users(tenant_id, search_term, role_filter) do
    # Use the search function from Accounts context
    users = if search_term != "" do
      Accounts.search_users(tenant_id, search_term)
    else
      Accounts.search_users(tenant_id, "")  # Empty search returns all
    end

    # Apply role filter
    case role_filter do
      "all" -> users
      role_id when is_binary(role_id) ->
        {role_id, _} = Integer.parse(role_id)
        Enum.filter(users, fn user ->
          case user.user_tenant_assignments do
            [assignment | _] -> assignment.role_id == role_id
            [] -> false
          end
        end)
      _ -> users
    end
  end

  defp can_manage_users?(user) do
    # Check if user has admin role or user management permissions
    # This should integrate with your permission system
    user.id != nil  # Placeholder - implement proper permission check
  end

  defp load_role_options do
    # Get dynamic roles from database
    roles = Accounts.get_available_roles()

    [{"All Roles", "all"}] ++
    Enum.map(roles, fn role -> {role.display_name || role.name, Integer.to_string(role.id)} end)
  end

  defp load_role_select_options do
    # Get roles for select dropdowns (without "All" option)
    roles = Accounts.get_available_roles()

    Enum.map(roles, fn role -> {role.display_name || role.name, Integer.to_string(role.id)} end)
  end
end
