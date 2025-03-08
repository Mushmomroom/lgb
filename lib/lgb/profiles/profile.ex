defmodule Lgb.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:handle, :state, :city, :height_cm, :weight_lb, :age, :gender],
    sortable: [:age, :height_cm, :weight_lb, :distance],
    default_limit: 6,
    adapter_opts: [
      alias_fields: [:distance]
    ]
  }

  schema "profiles" do
    has_many :messages, Lgb.Chatting.Message
    has_many :profile_pictures, Lgb.Profiles.ProfilePicture
    has_one :first_picture, Lgb.Profiles.ProfilePicture, foreign_key: :profile_id
    has_many :starred_profiles, Lgb.Profiles.Starred

    many_to_many :dating_goals, Lgb.Profiles.DatingGoal,
      join_through: "profiles_dating_goals",
      on_replace: :delete

    many_to_many :hobbies, Lgb.Profiles.Hobby,
      join_through: "profiles_hobbies",
      on_replace: :delete

    belongs_to :user, Lgb.Accounts.User
    field :handle, :string
    field :state, :string
    field :zip, :string
    field :age, :integer
    field :height_cm, :integer
    field :weight_lb, :integer
    field :city, :string
    field :biography, :string
    field :geolocation, Geo.PostGIS.Geometry
    field :distance, :float, virtual: true
    field :gender, Ecto.Enum, values: [:male, :female, :non_binary]
    field :uuid, Ecto.UUID, read_after_writes: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [
      :handle,
      :age,
      :height_cm,
      :weight_lb,
      :city,
      :state,
      :zip,
      :biography,
      :user_id,
      :geolocation,
      :gender
    ])
    |> validate_required([
      :user_id
    ])
    |> validate_number(:age,
      greater_than_or_equal_to: 18,
      less_than_or_equal_to: 100,
      message: "Age must be between 18 and 100"
    )

    # TODO: validate height, weight, zip to city is valid
  end

  def get_lat_lng(%{geolocation: %{coordinates: {lng, lat}}}), do: {lat, lng}
  def get_lat_lng(_), do: {nil, nil}
end
