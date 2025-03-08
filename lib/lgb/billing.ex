defmodule Lgb.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Lgb.Repo

  alias Lgb.Billing.StripeCustomer

  @doc """
  Returns the list of stripe_customers.

  ## Examples

      iex> list_stripe_customers()
      [%StripeCustomer{}, ...]

  """
  def list_stripe_customers do
    Repo.all(StripeCustomer)

  end

  @doc """
  Gets a single stripe_customer.

  Raises `Ecto.NoResultsError` if the Stripe customer does not exist.

  ## Examples

      iex> get_stripe_customer!(123)
      %StripeCustomer{}

      iex> get_stripe_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stripe_customer!(id), do: Repo.get!(StripeCustomer, id)

  @doc """
  Creates a stripe_customer.
  https://docs.stripe.com/api/customers/object?lang=curl
  ## Examples

      iex> create_stripe_customer(%{field: value})
      {:ok, %StripeCustomer{}}

      iex> create_stripe_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stripe_customer(user, param_body) do
    if Lgb.Accounts.get_stripe_customer(user) do
      {:error, "User already has a Stripe customer"}
    else
      params = %{
        "name" => param_body["name"],
        "email" => user.email,
        "address[line1]" => param_body["line1"],
        "address[line2]" => param_body["line2"],
        "address[city]" => param_body["city"],
        "address[state]" => param_body["state"],
        "address[postal_code]" => param_body["postal_code"],
        "address[country]" => param_body["country"]
      }

      case Lgb.ThirdParty.Stripe.create_stripe_customer(params) do
        {:ok, customer_metadata} ->
          %StripeCustomer{}
          |> StripeCustomer.changeset(%{
            "customer_id" => customer_metadata["id"],
            "user_id" => user.id
          })
          |> Repo.insert()

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Updates a stripe_customer.

  ## Examples

      iex> update_stripe_customer(stripe_customer, %{field: new_value})
      {:ok, %StripeCustomer{}}

      iex> update_stripe_customer(stripe_customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stripe_customer(%StripeCustomer{} = stripe_customer, attrs) do
    stripe_customer
    |> StripeCustomer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stripe_customer.

  ## Examples

      iex> delete_stripe_customer(stripe_customer)
      {:ok, %StripeCustomer{}}

      iex> delete_stripe_customer(stripe_customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stripe_customer(%StripeCustomer{} = stripe_customer) do
    Repo.delete(stripe_customer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stripe_customer changes.

  ## Examples

      iex> change_stripe_customer(stripe_customer)
      %Ecto.Changeset{data: %StripeCustomer{}}

  """
  def change_stripe_customer(%StripeCustomer{} = stripe_customer, attrs \\ %{}) do
    StripeCustomer.changeset(stripe_customer, attrs)
  end

  alias Lgb.Billing.StripeSubscription

  @doc """
    Want to get the current subscription if the user has one
  """
  def current_stripe_subscription(stripe_customer) do
    Repo.get_by(StripeSubscription, stripe_customer_id: stripe_customer.id)
  end

  @doc """
  Returns the list of stripe_subscriptions.

  ## Examples

      iex> list_stripe_subscriptions()
      [%StripeSubscription{}, ...]

  """
  def list_stripe_subscriptions do
    Repo.all(StripeSubscription)
  end

  @doc """
  Gets a single stripe_subscription.

  Raises `Ecto.NoResultsError` if the Stripe subscription does not exist.

  ## Examples

      iex> get_stripe_subscription!(123)
      %StripeSubscription{}

      iex> get_stripe_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stripe_subscription!(id), do: Repo.get!(StripeSubscription, id)

  def get_stripe_subscription(customer) do
    Repo.get_by(StripeSubscription, stripe_customer_id: customer.id)
  end

  @doc """
  Creates a stripe_subscription.

  ## Examples

      iex> create_stripe_subscription(%{field: value})
      {:ok, %StripeSubscription{}}

      iex> create_stripe_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stripe_subscription(customer, subscription_plan) do
    # first check if user already have a subscription and if not then we create it
    if Lgb.Billing.get_stripe_subscription(customer) do
      {:error, "User already has a Stripe subscription"}
    else
      params = %{
        "customer" => customer.customer_id,
        "items[0][plan]" => subscription_plan.stripe_price_id,
        "payment_behavior" => "default_incomplete",
        "payment_settings[save_default_payment_method]" => "on_subscription",
        "expand[]" => "latest_invoice.payment_intent",
        "metadata[initial_checkout_completed]" => "false"
      }

      case Lgb.ThirdParty.Stripe.create_stripe_subscription(params) do
        {:ok, response} ->
          %StripeSubscription{}
          |> StripeSubscription.changeset(%{
            "subscription_id" => response["id"],
            "stripe_customer_id" => customer.id,
            "subscription_plan_id" => subscription_plan.id
          })
          |> Repo.insert()

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def create_billing_portal(customer) do
    params = %{"customer" => customer.customer_id}

    case Lgb.ThirdParty.Stripe.create_stripe_session(params) do
      {:ok, response} ->
        {:ok, response["url"]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates a stripe_subscription.

  ## Examples

      iex> update_stripe_subscription(stripe_subscription, %{field: new_value})
      {:ok, %StripeSubscription{}}

      iex> update_stripe_subscription(stripe_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stripe_subscription(%StripeSubscription{} = stripe_subscription, attrs) do
    stripe_subscription
    |> StripeSubscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stripe_subscription.

  ## Examples

      iex> delete_stripe_subscription(stripe_subscription)
      {:ok, %StripeSubscription{}}

      iex> delete_stripe_subscription(stripe_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stripe_subscription(%StripeSubscription{} = stripe_subscription) do
    Repo.delete(stripe_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stripe_subscription changes.

  ## Examples

      iex> change_stripe_subscription(stripe_subscription)
      %Ecto.Changeset{data: %StripeSubscription{}}

  """
  def change_stripe_subscription(%StripeSubscription{} = stripe_subscription, attrs \\ %{}) do
    StripeSubscription.changeset(stripe_subscription, attrs)
  end

  def initial_checkout_completed?(stripe_subscription) do
    case Lgb.ThirdParty.Stripe.fetch_stripe_subscription(stripe_subscription) do
      {:ok, metadata} ->
        metadata["metadata"]["initial_checkout_completed"] == "true"

      {:error, message} ->
        Logger.error(message)
        false
    end
  end
end
