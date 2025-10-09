defmodule Shop1Cmms.AccountsFixtures do
  @moduledoc """
  This module defines test fixtures for Accounts context.
  """

  alias Shop1Cmms.Accounts
  alias Shop1Cmms.Tenants
  alias Shop1Cmms.Repo

  @doc """
  Generate a tenant.
  """
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "Test Tenant #{System.unique_integer([:positive])}",
        code: "TEST#{System.unique_integer([:positive])}",
        is_active: true
      })
      |> Tenants.create_tenant()

    tenant
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "user#{System.unique_integer([:positive])}@example.com",
        username: "user#{System.unique_integer([:positive])}",
        first_name: "Test",
        last_name: "User",
        is_active: true,
        cmms_enabled: true,
        password: "Password123456",
        password_confirmation: "Password123456"
      })
      |> Map.delete(:tenant_id)  # Remove tenant_id as it's not a User field
      |> Map.delete(:role)  # Remove role as it's not a User field
      |> Accounts.create_user_with_password()

    # Add tenant_id to the user struct for convenience in tests
    # In a real app, this would come from user_tenant_assignments
    Map.put(user, :tenant_id, tenant_id)
  end

  @doc """
  Generate a user password hash.
  """
  def valid_user_password, do: "password123456"

  @doc """
  Extract the token from the email to confirm account.
  """
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
