defmodule Shop1CmmsWeb.Router do
  use Shop1CmmsWeb, :router

  import Shop1CmmsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Shop1CmmsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Routes that require the user to NOT be authenticated
  scope "/", Shop1CmmsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/login", LoginLive, :index
  end

  # Authentication routes (no auth required, but handle completion)
  scope "/auth", Shop1CmmsWeb do
    pipe_through :browser

    get "/login-complete", AuthController, :login_complete
    live "/select-tenant", TenantSelectLive, :index
    get "/logout", AuthController, :logout
  end

  # Routes that require authentication but not necessarily tenant selection
  scope "/", Shop1CmmsWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/select-tenant", AuthController, :switch_tenant
  end

  # Main application routes - require authentication and tenant access
  scope "/", Shop1CmmsWeb do
    pipe_through [:browser, :require_authenticated_user, :require_tenant_access]

    live_session :authenticated,
      on_mount: [
        {Shop1CmmsWeb.UserAuth, :mount_current_user},
        {Shop1CmmsWeb.UserAuth, :ensure_tenant_access},
        {Shop1CmmsWeb.UserAuth, :load_navigation_data}
      ] do

      # Dashboard
      live "/", DashboardLive, :index
      live "/dashboard", DashboardLive, :index

      # Work Orders (coming soon)
      # live "/work-orders", WorkOrderLive.Index, :index
      # live "/work-orders/new", WorkOrderLive.Index, :new
      # live "/work-orders/:id", WorkOrderLive.Show, :show
      # live "/work-orders/:id/edit", WorkOrderLive.Show, :edit

      # Assets
      live "/assets", AssetsLive, :index
      live "/assets/new", AssetsLive, :new
      live "/assets/:id", AssetDetailLive, :show
      live "/assets/:id/edit", AssetsLive, :edit

      # Preventive Maintenance (coming soon)
      # live "/preventive-maintenance", PMTemplateLive.Index, :index
      # live "/preventive-maintenance/new", PMTemplateLive.Index, :new
      # live "/preventive-maintenance/:id", PMTemplateLive.Show, :show
      # live "/preventive-maintenance/:id/edit", PMTemplateLive.Show, :edit

      # Reports (coming soon)
      # live "/reports", ReportLive.Index, :index
      # live "/reports/:type", ReportLive.Show, :show

      # Admin interface (coming soon)
      # live "/admin", AdminLive.Index, :index
      # live "/admin/users", AdminLive.Users, :index
      # live "/admin/tenants", AdminLive.Tenants, :index
      # live "/admin/sites", AdminLive.Sites, :index
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:shop1_cmms, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Shop1CmmsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
