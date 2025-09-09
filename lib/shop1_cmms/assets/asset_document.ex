defmodule Shop1Cmms.Assets.AssetDocument do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "asset_documents" do
    field :name, :string
    field :description, :string
    field :file_path, :string
    field :file_size, :integer
    field :file_type, :string
    field :document_type, :string
  # tenant_id provided via belongs_to :tenant

    # Associations
  # The FK column should be uploaded_by_id by convention
  belongs_to :uploaded_by, Shop1Cmms.Accounts.User, foreign_key: :uploaded_by_id, type: :integer
    belongs_to :asset, Shop1Cmms.Assets.Asset, foreign_key: :asset_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(asset_document, attrs) do
    asset_document
  |> cast(attrs, [:name, :description, :file_path, :file_size, :file_type,
          :document_type, :tenant_id, :uploaded_by_id, :asset_id])
  |> validate_required([:name, :file_path, :document_type, :tenant_id, :asset_id])
    |> validate_length(:name, max: 255)
    |> validate_inclusion(:document_type, ["manual", "photo", "drawing", "certificate",
                                          "warranty", "specification", "maintenance_record", "other"])
    |> validate_number(:file_size, greater_than: 0)
    |> validate_file_type()
  end

  defp validate_file_type(changeset) do
    case get_field(changeset, :file_type) do
      nil -> changeset
      file_type ->
        allowed_types = [
          "application/pdf", "image/jpeg", "image/png", "image/gif", "image/webp",
          "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "text/plain", "text/csv"
        ]

        if file_type in allowed_types do
          changeset
        else
          add_error(changeset, :file_type, "file type not supported")
        end
    end
  end

  def for_tenant(query, tenant_id), do: from(q in query, where: q.tenant_id == ^tenant_id)
  def for_asset(query, asset_id), do: from(q in query, where: q.asset_id == ^asset_id)
  def by_document_type(query, document_type), do: from(q in query, where: q.document_type == ^document_type)
  def by_file_type(query, file_type), do: from(q in query, where: q.file_type == ^file_type)
  def recent_first(query), do: from(q in query, order_by: [desc: q.inserted_at])
end
