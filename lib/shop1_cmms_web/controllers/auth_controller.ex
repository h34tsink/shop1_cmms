defmodule Shop1CmmsWeb.AuthController do
  use Shop1CmmsWeb, :controller

  alias Shop1Cmms.{Auth, Accounts}
  alias Shop1CmmsWeb.UserAuth

  def login_complete(conn, %{"user_id" => user_id, "tenant_id" => tenant_id} = params) do
    remember_me = params["remember_me"] == "true"

    with user_id <- String.to_integer(user_id),
         tenant_id <- String.to_integer(tenant_id),
         %{cmms_enabled: true} = user <- Accounts.get_user_with_details(user_id),
         {:ok, _user} <- Auth.validate_tenant_access(user, tenant_id) do
      
      login_params = if remember_me, do: %{"remember_me" => "true"}, else: %{}
      
      conn
      |> UserAuth.log_in_user(user, tenant_id, login_params)
      |> put_flash(:info, "Welcome to Shop1 CMMS!")
      |> redirect(to: ~p"/dashboard")
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid login session. Please try again.")
        |> redirect(to: ~p"/login")
    end
  end

  def logout(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "You have been logged out successfully.")
    |> redirect(to: ~p"/login")
  end

  def switch_tenant(conn, %{"tenant_id" => tenant_id}) do
    current_user = conn.assigns[:current_user]
    tenant_id = String.to_integer(tenant_id)

    case Auth.validate_tenant_access(current_user, tenant_id) do
      {:ok, _user} ->
        conn
        |> put_session(:tenant_id, tenant_id)
        |> then(fn conn ->
          # Re-establish session context
          Auth.establish_session_context(current_user.id, tenant_id)
          conn
        end)
        |> put_flash(:info, "Switched tenant successfully.")
        |> redirect(to: ~p"/dashboard")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "You don't have access to this tenant.")
        |> redirect(to: ~p"/select-tenant")
    end
  end
end
