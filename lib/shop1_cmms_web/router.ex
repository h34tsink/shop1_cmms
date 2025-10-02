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

      # Work Orders
      live "/work_orders", WorkOrdersLive, :index
      live "/work_orders/new", WorkOrdersLive, :new
      live "/work_orders/:id", WorkOrderDetailLive, :show
      live "/work_orders/:id/edit", WorkOrdersLive, :edit

      # Equipment
      live "/assets", AssetsLive, :index
      live "/assets/new", AssetsLive, :new
      live "/assets/:id", AssetDetailLive, :show
      live "/assets/:id/edit", AssetsLive, :edit

      # Preventive Maintenance
      live "/pm-schedules", PmSchedulesLive, :index
      live "/pm-schedules/new", PmSchedulesLive, :new
      live "/pm-schedules/:id", PmScheduleDetailLive, :show
      live "/pm-schedules/:id/edit", PmSchedulesLive, :edit

      # Reports (coming soon)
      # live "/reports", ReportLive.Index, :index
      # live "/reports/:type", ReportLive.Show, :show

      # Configuration / Metadata Management
      live "/configuration/:type", MetadataLive, :index
      live "/configuration/:type/new", MetadataLive, :new
      live "/configuration/:type/:id/edit", MetadataLive, :edit

      # User Management
      live "/admin/users", UserManagementLive, :index
      live "/admin/users/new", UserManagementLive, :new
      live "/admin/users/:id/edit", UserManagementLive, :edit
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
