defmodule AccountsManagementAPIWeb.Router do
  use AccountsManagementAPIWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth do
    plug AccountsManagementAPIWeb.Auth.Pipeline
  end

  # Unsecure routes
  scope "/api", AccountsManagementAPIWeb do
    pipe_through :api

    resources "/auth", AuthController, only: [:create] do
      resources "/refresh", AuthController, only: [:create]
    end

    resources "/accounts", AccountController, only: [:create]
  end

  # Secure routes
  scope "/api", AccountsManagementAPIWeb do
    pipe_through [:api, :auth]

    resources "/accounts", AccountController, only: [:index, :show, :update, :delete] do
      resources("/addresses", AddressController, only: [:index, :create, :show, :update, :delete])
      resources("/phones", PhoneController, only: [:index, :create, :show, :update, :delete])
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:accounts_management_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: AccountsManagementAPIWeb.Telemetry)
    end
  end
end
