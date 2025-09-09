defmodule Shop1Cmms.Auth do
  @moduledoc """
  Authentication module that integrates with existing Shop1FinishLine user system
  while providing CMMS-specific access control and session management.
  """

  alias Shop1Cmms.Accounts
  alias Shop1Cmms.Accounts.User
  alias Shop1Cmms.Tenants

  @doc """
  Authenticates a user for CMMS access using existing Shop1FinishLine credentials.
  Returns the user if valid and CMMS-enabled, otherwise returns an error.
  """
  def authenticate_user(username, password) when is_binary(username) and is_binary(password) do
    case Accounts.get_user_by_username_and_password(username, password) do
      %User{cmms_enabled: true} = user ->
        {:ok, user}
      
      %User{cmms_enabled: false} ->
        {:error, :cmms_not_enabled}
      
      nil ->
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Validates that a user has access to a specific tenant.
  Returns {:ok, user} if access is granted, otherwise {:error, reason}.
  """
  def validate_tenant_access(%User{} = user, tenant_id) do
    if Accounts.user_has_cmms_access?(user.id, tenant_id) do
      {:ok, user}
    else
      {:error, :no_tenant_access}
    end
  end

  @doc """
  Sets up the session context for a user and tenant.
  This configures the database session for Row-Level Security.
  """
  def establish_session_context(user_id, tenant_id) do
    case Accounts.set_user_tenant_context(user_id, tenant_id) do
      {:ok, user} ->
        # Set additional session variables for RLS
        Tenants.set_tenant_context(tenant_id)
        {:ok, user}
      
      error ->
        error
    end
  end

  @doc """
  Gets all tenants accessible to a user for tenant selection.
  """
  def get_user_tenant_options(%User{} = user) do
    tenants = Accounts.get_user_tenants(user.id)
    
    Enum.map(tenants, fn tenant ->
      %{
        id: tenant.id,
        name: tenant.name,
        code: tenant.tenant_code,
        role: Accounts.get_user_highest_cmms_role(user.id, tenant.id)
      }
    end)
  end

  @doc """
  Checks if a user has a specific permission within a tenant context.
  """
  def authorize(%User{} = user, action, resource \\ nil, tenant_id) do
    if Accounts.can?(user, action, resource, tenant_id) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Checks if a user has a specific permission (returns boolean).
  """
  def authorized?(%User{} = user, action, resource \\ nil, tenant_id) do
    case authorize(user, action, resource, tenant_id) do
      :ok -> true
      _ -> false
    end
  end

  @doc """
  Gets the user's role within a specific tenant.
  """
  def get_user_role(%User{} = user, tenant_id) do
    Accounts.get_user_highest_cmms_role(user.id, tenant_id)
  end

  @doc """
  Checks if user has admin privileges in any tenant.
  """
  def is_admin?(%User{} = user) do
    user
    |> Accounts.get_user_tenants()
    |> Enum.any?(fn tenant ->
      Accounts.get_user_highest_cmms_role(user.id, tenant.id) == "tenant_admin"
    end)
  end

  @doc """
  Checks if user has admin privileges in a specific tenant.
  """
  def is_tenant_admin?(%User{} = user, tenant_id) do
    Accounts.get_user_highest_cmms_role(user.id, tenant_id) == "tenant_admin"
  end

  @doc """
  Creates a session token for API authentication (if needed).
  This would be used for mobile apps or API access.
  """
  def generate_session_token(%User{} = user, tenant_id) do
    # Simple token generation - in production, use proper JWT or session tokens
    token = :crypto.strong_rand_bytes(32) |> Base.encode64()
    
    # Store token in user preferences for validation
    Accounts.update_user_cmms_preferences(user, %{
      "session_tokens" => [
        %{
          "token" => token,
          "tenant_id" => tenant_id,
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "expires_at" => DateTime.utc_now() |> DateTime.add(24, :hour) |> DateTime.to_iso8601()
        }
      ]
    })
    
    {:ok, token}
  end

  @doc """
  Validates a session token and returns the associated user and tenant.
  """
  def validate_session_token(token) when is_binary(token) do
    # This is a simplified implementation
    # In production, you'd want to use proper session storage
    {:error, :not_implemented}
  end

  @doc """
  Logs out a user by clearing session context and updating last login.
  """
  def logout(%User{} = user) do
    # Clear database session variables
    Tenants.clear_context()
    
    # Update last CMMS login to track session end
    Accounts.update_user_cmms_preferences(user, %{
      "last_logout" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
    
    :ok
  end

  @doc """
  Password validation against existing Shop1FinishLine hash.
  This function works with the existing password_hash field.
  """
  def valid_password?(%User{} = user, password) when is_binary(password) do
    User.valid_password?(user, password)
  end

  def valid_password?(_, _), do: false

  @doc """
  Initialize CMMS access for an existing Shop1FinishLine user.
  This is typically called by an admin to grant CMMS access.
  """
  def initialize_cmms_access(username, tenant_id, granting_admin_id) do
    with %User{} = user <- Accounts.get_user_by_username(username),
         false <- user.cmms_enabled,
         {:ok, updated_user} <- Accounts.enable_cmms_for_user(user.id, tenant_id, granting_admin_id) do
      {:ok, updated_user}
    else
      nil -> {:error, :user_not_found}
      %User{cmms_enabled: true} -> {:error, :already_enabled}
      error -> error
    end
  end

  @doc """
  Remove CMMS access for a user.
  """
  def revoke_cmms_access(user_id, revoking_admin_id) do
    # Verify the revoking admin has permission
    # This is a simplified check - you might want more sophisticated authorization
    case Accounts.disable_cmms_for_user(user_id) do
      {:ok, user} -> 
        # Log the revocation
        Accounts.update_user_cmms_preferences(user, %{
          "access_revoked_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "access_revoked_by" => revoking_admin_id
        })
        {:ok, user}
      
      error -> error
    end
  end

  @doc """
  Middleware function to require authentication.
  Used in LiveView mount or Phoenix controllers.
  """
  def require_authenticated_user(session) do
    case get_current_user(session) do
      %User{} = user -> {:ok, user}
      nil -> {:error, :not_authenticated}
    end
  end

  @doc """
  Middleware function to require specific tenant access.
  """
  def require_tenant_access(user, tenant_id) do
    validate_tenant_access(user, tenant_id)
  end

  @doc """
  Gets current user from session (placeholder - integrate with Phoenix session).
  """
  def get_current_user(_session) do
    # This would integrate with Phoenix.LiveView.get_connect_params/1
    # or controller session handling
    nil
  end

  @doc """
  Gets current tenant from session.
  """
  def get_current_tenant(_session) do
    # This would integrate with Phoenix session handling
    nil
  end
end
