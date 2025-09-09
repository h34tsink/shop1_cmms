defmodule Shop1CmmsWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such as controllers,
  components, channels, and so on.

  This can be used in your application as:

      use Shop1CmmsWeb, :controller
      use Shop1CmmsWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused on imports,
  uses and aliases.

  Do NOT define functions inside the quoted expressions below. Instead,
  call the function you want to define in the module. For example,
  define your own `format_date/1` function in the `Shop1CmmsWeb.Helpers`
  module and call it in your templates or controllers.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: Shop1CmmsWeb,
        formats: [:html, :json],
        layouts: [html: Shop1CmmsWeb.Layouts]

      import Plug.Conn
      import Shop1CmmsWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Shop1CmmsWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import Shop1CmmsWeb.CoreComponents
      import Shop1CmmsWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Shop1CmmsWeb.Endpoint,
        router: Shop1CmmsWeb.Router,
        statics: Shop1CmmsWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
