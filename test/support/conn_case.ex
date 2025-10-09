defmodule Shop1CmmsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Shop1CmmsWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint Shop1CmmsWeb.Endpoint

      use Shop1CmmsWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Shop1CmmsWeb.ConnCase
    end
  end

  setup tags do
    Shop1Cmms.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in a user in a test conn.
  
  ## Examples
  
      setup :register_and_log_in_user
      
  It stores a user in the test shared state or creates one with a tenant assignment.
  """
  def register_and_log_in_user(context) do
    conn = context[:conn] || Phoenix.ConnTest.build_conn()
    tenant = context[:tenant]
    user = context[:user]
    
    # Ensure we have user and tenant
    {user, tenant_id} = cond do
      user && tenant -> 
        # Ensure user has tenant assignment
        ensure_user_tenant_assignment(user, tenant.id)
        {Map.put(user, :tenant_id, tenant.id), tenant.id}
      
      user && !tenant ->
        # Use user's tenant_id or default to 1
        tenant_id = Map.get(user, :tenant_id, 1)
        ensure_user_tenant_assignment(user, tenant_id)
        {Map.put(user, :tenant_id, tenant_id), tenant_id}
      
      true ->
        # Create new user with tenant assignment
        user = Shop1Cmms.Factory.insert_user_with_tenant(tenant_id: 1)
        {user, 1}
    end
    
    %{user: user, conn: log_in_user(conn, user)}
  end
  
  defp ensure_user_tenant_assignment(user, tenant_id) do
    alias Shop1Cmms.Accounts
    alias Shop1Cmms.Accounts.UserTenantAssignment
    alias Shop1Cmms.Repo
    
    # Check if assignment already exists
    existing = Repo.get_by(UserTenantAssignment, user_id: user.id, tenant_id: tenant_id)
    
    if !existing do
      # Create assignment
      role = Shop1Cmms.Factory.get_or_create_role("technician")
      Accounts.create_user_tenant_assignment(%{
        user_id: user.id,
        tenant_id: tenant_id,
        role_id: role.id,
        is_active: true
      })
    end
  end

  @doc """
  Setup helper that logs in a user in a test conn.
  """
  def log_in_user(conn, user) do
    # Try to get tenant_id from user struct or use default
    tenant_id = Map.get(user, :tenant_id, 1)
    token = :crypto.strong_rand_bytes(32) |> Base.encode64()

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
    |> Plug.Conn.put_session(:tenant_id, tenant_id)
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{user.id}")
  end
end
