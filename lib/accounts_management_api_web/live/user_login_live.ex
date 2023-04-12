defmodule AccountsManagementAPIWeb.UserLoginLive do
  use AccountsManagementAPIWeb, :live_view

  attr :register_url, :string, default: "/users/register"
  attr :login_url, :string, default: "/users/log_in"
  attr :done_url, :string, default: "/"
  attr :reset_pass_url, :string, default: "/users/reset_password"

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Sign in to user
        <:subtitle>
          Don't have an user?
          <.link navigate={@register_url} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an user now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={@login_url} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={@reset_pass_url} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
