defmodule Lgb.ThirdParty.Stripe do
  alias Lgb.ThirdParty.Stripe.Customers

  @doc """

  reponse
  {
    "id": "cus_NffrFeUfNV2Hib",
    "object": "customer",
    "address": null,
    "balance": 0,
    "created": 1680893993,
    "currency": null,
    "default_source": null,
    "delinquent": false,
    "description": null,
    "discount": null,
    "email": "jennyrosen@example.com",
    "invoice_prefix": "0759376C",
    "invoice_settings": {
      "custom_fields": null,
      "default_payment_method": null,
      "footer": null,
      "rendering_options": null
    },
    "livemode": false,
    "metadata": {},
    "name": "Jenny Rosen",
    "next_invoice_sequence": 1,
    "phone": null,
    "preferred_locales": [],
    "shipping": null,
    "tax_exempt": "none",
    "test_clock": null
  }
  """
  def fetch_stripe_customer(stripe_customer) do
    case Customers.get("/#{stripe_customer.customer_id}") do
      {:ok, http_response} ->
        {:ok, Poison.decode!(http_response.body)}

      {:error, whatever} ->
        {:error, whatever.message}
    end
  end

  def fetch_stripe_subscription(stripe_subscription) do
    if is_nil(stripe_subscription) or is_nil(stripe_subscription.subscription_id) do
      {:ok, %{}}
    else
      case Lgb.ThirdParty.Stripe.Subscriptions.get("/#{stripe_subscription.subscription_id}") do
        {:ok, http_response} ->
          {:ok, Poison.decode!(http_response.body)}

        {:error, whatever} ->
          {:error, whatever.message}
      end
    end
  end

  def update_stripe_subscription!(stripe_subscription, body) do
    encode_body = URI.encode_query(body)

    Lgb.ThirdParty.Stripe.Subscriptions.post!(
      "/#{stripe_subscription.subscription_id}",
      encode_body
    )
  end

  def create_stripe_customer(body) do
    encoded_body = URI.encode_query(body)

    case Lgb.ThirdParty.Stripe.Customers.post("", encoded_body) do
      {:ok, http_response} ->
        {:ok, Poison.decode!(http_response.body)}

      {:error, reason} ->
        {:error, reason.message}
    end
  end

  def create_stripe_subscription(body) do
    encoded_body = URI.encode_query(body)

    case Lgb.ThirdParty.Stripe.Subscriptions.post("", encoded_body) do
      {:ok, http_response} -> {:ok, Poison.decode!(http_response.body)}
      {:error, reason} -> {:error, reason.message}
    end
  end

  def create_stripe_session(body) do
    encoded_body = URI.encode_query(body)

    case Lgb.ThirdParty.Stripe.BillingPortal.post("", encoded_body) do
      {:ok, http_response} -> {:ok, Poison.decode!(http_response.body)}
      {:error, reason} -> {:error, reason.message}
    end
  end

  def get_stripe_charge(id) do
    case Lgb.ThirdParty.Stripe.Charge.get("/#{id}") do
      {:ok, http_response} -> {:ok, Poison.decode!(http_response.body)}
      {:error, reason} -> {:error, reason.message}
    end
  end

  def fetch_payment_intent(id) do
    case Lgb.ThirdParty.Stripe.PaymentIntents.get("/#{id}") do
      {:ok, http_response} -> {:ok, Poison.decode!(http_response.body)}
      {:error, reason} -> {:error, reason.message}
    end
  end
end
