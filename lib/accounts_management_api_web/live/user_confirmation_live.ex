defmodule AccountsManagementAPIWeb.UserConfirmationLive do
  use AccountsManagementAPIWeb, :live_view

  alias AccountsManagementAPI.Accounts

  attr :register_url, :string, default: "/users/register"
  attr :login_url, :string, default: "/users/log_in"
  attr :done_url, :string, default: "/"

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">Confirm User</.header>

      <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
        <.input field={@form[:token]} type="hidden" />
        <:actions>
          <.button phx-disable-with="Confirming..." class="w-full">Confirm my user</.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={@register_url}>Register</.link> | <.link href={@login_url}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the user.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: socket.assigns.done_url)}

      :error ->
        # If there is a current user and the user was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: socket.assigns.done_url)}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: socket.assigns.done_url)}
        end
    end
  end
end
