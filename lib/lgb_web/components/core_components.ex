defmodule LgbWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: LgbWeb.Endpoint,
    router: LgbWeb.Router

  alias Phoenix.LiveView.JS
  import LgbWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-white bg-opacity-75 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center p-4 sm:p-6 lg:py-8">
          <div class="w-full max-w-3xl">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={["fixed top-2 right-2 z-50 mr-2 w-80 rounded-lg p-3 ring-1 sm:w-96", @kind == :info && "bg-emerald-50 fill-cyan-900 text-emerald-800 ring-emerald-500", @kind == :error && "bg-rose-50 fill-rose-900 text-rose-900 shadow-md ring-rose-500"]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="collapsible mt-10 flex flex-col space-y-8 rounded-md p-2">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def general_chat_simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="flex items-center gap-2 space-y-8 rounded-md bg-white p-2 shadow-md">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def profile_simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="collapsible flex flex-col gap-4 rounded-md bg-white p-2 shadow-md">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def chat_simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="collapsible flex flex-col rounded-md bg-white shadow-md">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={["bg-gradient-to-r from-purple-500 to-blue-600 phx-submit-loading:opacity-75", "flex items-center gap-2 rounded-full px-6 py-2 text-white shadow-md hover:opacity-90", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
      <span class="text-lg">›</span>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week radio)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="flex items-center gap-2">
      <input
        type="radio"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        class="h-4 w-4 cursor-pointer border-gray-300 text-purple-600 transition-all duration-200 ease-in-out checked:shadow-[0_0_0_2px_rgba(147,51,234,0.3)] hover:ring-2 hover:ring-purple-300 hover:ring-opacity-50 hover:checked:ring-purple-400/75 focus:ring-2 focus:ring-purple-500 focus:ring-opacity-50 focus:checked:ring-purple-500/75"
        {@rest}
      />
      <.label for={@id} class="cursor-pointer select-none text-sm font-medium text-gray-700">
        {@label}
      </.label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={["mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6", "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400", @errors == [] && "border-zinc-300 focus:border-zinc-400", @errors != [] && "border-rose-400 focus:border-rose-400"]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="w-full">
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={["mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6", "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400", @errors == [] && "border-zinc-300 focus:border-zinc-400", @errors != [] && "border-rose-400 focus:border-rose-400"]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm leading-6">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-medium leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm leading-6">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto sm:overflow-visible">
      <table class="w-full">
        <thead class="text-left text-sm leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="pt-2 pr-4 pb-2 pl-2 font-normal">{col[:label]}</th>

            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative pl-2 ", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 " />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def billing_list(assigns) do
    ~H"""
    <div>
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :entries, :list, default: []

  def unordered_list(assigns) do
    ~H"""
    <div>
      <ul :for={entry <- @entries}>
        <li>{render_slot(@inner_block, entry)}</li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(LgbWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(LgbWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Page Align
  """
  slot :inner_block, required: true
  attr :no_padding, :boolean, default: false

  def page_align(assigns) do
    ~H"""
    <div class="mx-auto flex min-h-full max-w-7xl flex-col justify-center md:flex-row">
      <!-- Sidebar Navigation with fixed width -->
      <.live_component
        id={"page-align-#{assigns.current_user.uuid}"}
        module={LgbWeb.Components.SignedInNav}
        current_user={assigns.current_user}
      />
      
    <!-- Main Content that takes most of the width -->
      <main class={["w-full flex-1", if(@no_padding, do: "p-0", else: "p-4")]}>
        <div class={["h-full", if(@no_padding, do: "px-4", else: "mx-auto max-w-5xl")]}>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :no_padding, :boolean, default: false

  def wide_page_align(assigns) do
    ~H"""
    <div class={["flex min-h-full flex-col md:flex-row"]}>
      <!-- Sidebar Navigation -->
      <.live_component
        id={"chatrooms-page-align-#{assigns.current_user.uuid}"}
        module={LgbWeb.Components.SignedInNav}
        current_user={assigns.current_user}
      />
      <!-- Main Content -->
      <main class={["flex-1", if(@no_padding,
    do: "p-0",
    else: "p-4")]}>
        <div class={[if(@no_padding,
    do: "h-full px-4",
    else: "w-[80vw] mx-auto flex flex-col")]}>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :no_padding, :boolean, default: false

  def profile_page_align(assigns) do
    ~H"""
    <div class={["flex min-h-full flex-col md:flex-row"]}>
      <!-- Sidebar Navigation -->
      <.live_component
        id={"profile-page-align-#{assigns.current_user.uuid}"}
        module={LgbWeb.Components.SignedInNav}
        current_user={assigns.current_user}
      />
      <!-- Main Content -->
      <main class={["flex-1", if(@no_padding,
    do: "p-0",
    else: "p-4")]}>
        <div class={[if(@no_padding,
    do: "h-full px-4",
    else: "w-[80vw] mx-auto flex flex-col")]}>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :no_padding, :boolean, default: false

  def general_chatroom_page_align(assigns) do
    ~H"""
    <div class={["flex min-h-full flex-col md:flex-row"]}>
      <!-- Sidebar Navigation -->
      <.live_component
        id={"general-chatroom-page-align-#{assigns.current_user.uuid}"}
        module={LgbWeb.Components.SignedInNav}
        current_user={assigns.current_user}
      />
      <!-- Main Content -->
      <main class={["flex-1", if(@no_padding,
    do: "p-0",
    else: "p-4")]}>
        <div class={[if(@no_padding,
    do: "px-4",
    else: "w-[80vw] mx-auto flex flex-col")]}>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  slot :title
  attr :subtitle, :string
  attr :picture_url, :string, required: true
  attr :unread_messages, :integer, required: false
  slot :trailer, required: true

  def list_tile(assigns) do
    ~H"""
    <div class="rounded-lg p-3 transition-all duration-200 hover:bg-white hover:shadow-md sm:p-4">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4">
        <img
          src={@picture_url}
          alt="Avatar"
          class="h-12 w-12 rounded-full object-cover ring-2 ring-gray-100 transition-all hover:ring-purple-200 sm:h-16 sm:w-16"
        />
        <div class="min-w-0 flex-1">
          <h3 class="truncate text-base font-medium text-gray-900 group-hover:text-purple-900 sm:text-lg">
            {@title}
          </h3>
          <p class="truncate text-sm text-gray-500 sm:text-base">
            {@subtitle}
          </p>
        </div>
        <div class="flex w-full items-center justify-between gap-2 sm:w-auto sm:justify-end">
          <%= if @unread_messages && @unread_messages > 0 do %>
            <div class="unread-message">
              {@unread_messages}
            </div>
          <% end %>
          {render_slot(@trailer)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Card component
  """

  attr :class, :string, default: nil, doc: "Custom CSS classes to be added to the card."
  attr :no_background, :boolean, default: true
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["rounded-lg", @class, if(@no_background, do: "border bg-white p-2", else: "")]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Non logged in navbar
  """
  slot :inner_block, required: true

  def non_logged_in_nav(assigns) do
    ~H"""
    <div class="relative min-h-screen">
      <!-- Navigation Bar -->
      <nav id="non-signed-in-nav" class="sticky top-0 z-10 w-full px-4 py-4 backdrop-blur-md">
        <div class="mx-auto flex w-full max-w-6xl items-center justify-between">
          <!-- Logo -->
          <div class="flex items-center">
            <.link navigate={~p"/"} class="focus:outline-none">
              <h1 class="font-sans bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-3xl font-bold text-transparent">
                bi⏾bi
              </h1>
            </.link>
          </div>
          
    <!-- Desktop Navigation Links -->
          <div class="hidden md:flex md:items-center">
            <div class="mr-8 flex items-center space-x-1" id="desktop-nav-link-nonsigned-in">
              <a href="/products" class="navLinks">Products</a>
              <a href="/features" class="navLinks">Features</a>
              <a href="/blogs" class="navLinks">Blogs</a>
              <a href="/community" class="navLinks">Community </a>
              <a href="/pricing" class="navLinks">Pricing </a>
            </div>

            <.link
              navigate={~p"/users/log_in"}
              id="non-signed-in-nav-login"
              class="rounded-full bg-gradient-to-r from-purple-600 to-blue-600 px-4 py-2 font-medium text-white transition-colors hover:from-purple-700 hover:to-blue-700"
            >
              Log In
            </.link>
          </div>
          
    <!-- Mobile Menu Button -->
          <button
            type="button"
            class="flex items-center md:hidden"
            onclick="expandNavigation()"
            aria-label="Toggle menu"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="size-6"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 9h16.5m-16.5 6.75h16.5" />
            </svg>
          </button>
          
    <!-- Mobile Navigation Slide-out -->
          <div class="navs fixed top-0 left-0 z-50 h-screen w-0 overflow-x-hidden bg-white shadow-lg transition-all duration-300 md:hidden">
            <div class="flex flex-col space-y-6 p-6">
              <div class="flex items-center justify-between">
                <h1 class="font-sans bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-3xl font-bold text-transparent">
                  bi⏾bi
                </h1>
                <button
                  class="rounded-full p-2 hover:bg-gray-100"
                  onclick="closeNavigation()"
                  aria-label="Close menu"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="size-6"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div class="flex flex-col space-y-4 pt-4">
                <a href="/products" class="py-2 text-lg text-gray-700 hover:text-gray-900">
                  Products
                </a>
                <a href="/features" class="py-2 text-lg text-gray-700 hover:text-gray-900">
                  Features
                </a>
                <a href="/blogs" class="py-2 text-lg text-gray-700 hover:text-gray-900">Blogs</a>
                <a href="/community" class="py-2 text-lg text-gray-700 hover:text-gray-900">
                  Community
                </a>
                <a href="/pricing" class="py-2 text-lg text-gray-700 hover:text-gray-900">Pricing</a>
                <.link
                  navigate={~p"/users/log_in"}
                  class="mt-4 rounded-full bg-gradient-to-r from-purple-600 to-blue-600 px-4 py-3 text-center font-medium text-white"
                >
                  Log In
                </.link>
              </div>
            </div>
          </div>
        </div>
      </nav>
      
    <!-- Main Content -->
      <main class="min-h-[calc(100vh-5rem)]">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  @doc """
  name activity
  """

  attr :show, :boolean, default: false
  attr :profile, :map, required: true

  def name_with_online_activity(assigns) do
    user = assigns.profile.user
    is_online = LgbWeb.Presence.find_user("users", user.id) != nil

    assigns = assign(assigns, :is_online, is_online)

    ~H"""
    <div class="flex items-center gap-2 rounded-lg p-1 transition-all">
      <div class="flex items-center gap-2">
        <!-- Online indicator -->
        <%= if @is_online do %>
          <div class="relative flex">
            <div class="h-2 w-2 rounded-full bg-green-400"></div>
            <div class="absolute h-2 w-2 animate-ping rounded-full bg-green-400 opacity-75"></div>
          </div>
        <% end %>
        
    <!-- Profile name -->
        <.link navigate={~p"/profiles/#{@profile.uuid}"} class="link-style">
          <div class="text-lg font-light text-black">
            {@profile.handle || "⋆.˚"}
          </div>
        </.link>
        
    <!-- Last active status (only shown when user is offline) -->
        <%= if !@is_online && @profile.user.last_login_at && @show do %>
          <div class="text-xs font-light text-gray-400">
            <%= cond do %>
              <% LgbWeb.UserPresence.within_minutes?(@profile.user.last_login_at, 60) -> %>
                {LgbWeb.UserPresence.format_hours_ago(@profile.user.last_login_at)}
              <% LgbWeb.UserPresence.within_hours?(@profile.user.last_login_at, 24) -> %>
                Last active yesterday
              <% true -> %>
                Last active {Calendar.strftime(@profile.user.last_login_at, "%b %d")}
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  slot :inner_block, required: true

  def blog(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mx-auto max-w-xl">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
