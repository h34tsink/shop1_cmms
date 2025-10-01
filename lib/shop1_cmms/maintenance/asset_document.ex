defmodule Shop1Cmms.Maintenance.AssetDocument do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @document_type_values [:manual, :drawing, :specification, :procedure, :work_instruction, :certificate, :calibration, :warranty, :other]

  schema "asset_documents" do
    field :document_number, :string
    field :title, :string
    field :description, :string
    field :document_type, Ecto.Enum, values: @document_type_values
    
    # File information
    field :file_name, :string
    field :file_path, :string
    field :file_size, :integer
    field :mime_type, :string
    field :file_url, :string
    
    # Document metadata
    field :version, :string
    field :revision_date, :date
    field :expiry_date, :date
    field :issued_by, :string
    field :approved_by, :string
    
    # Tags and categories
    field :tags, {:array, :string}, default: []
    field :is_active, :boolean, default: true
    
    # References - can be attached to asset, PM schedule, or work order
    belongs_to :asset, Shop1Cmms.Assets.Asset, type: :binary_id
    belongs_to :pm_schedule, Shop1Cmms.Maintenance.PmSchedule, type: :binary_id
    belongs_to :work_order, Shop1Cmms.WorkOrders.WorkOrder, type: :binary_id
    
    field :uploaded_by, :integer
    field :tenant_id, :integer
    
    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :document_number, :title, :description, :document_type,
      :file_name, :file_path, :file_size, :mime_type, :file_url,
      :version, :revision_date, :expiry_date, :issued_by, :approved_by,
      :tags, :is_active,
      :asset_id, :pm_schedule_id, :work_order_id, :uploaded_by, :tenant_id
    ])
    |> validate_required([:title, :document_type, :tenant_id])
    |> validate_inclusion(:document_type, @document_type_values)
    |> validate_length(:title, min: 3, max: 255)
    |> validate_at_least_one_reference()
  end

  defp validate_at_least_one_reference(changeset) do
    asset_id = get_field(changeset, :asset_id)
    pm_schedule_id = get_field(changeset, :pm_schedule_id)
    work_order_id = get_field(changeset, :work_order_id)
    
    if is_nil(asset_id) and is_nil(pm_schedule_id) and is_nil(work_order_id) do
      add_error(changeset, :asset_id, "must have at least one reference (asset, PM schedule, or work order)")
    else
      changeset
    end
  end

  # Helper functions
  def document_type_values, do: @document_type_values
  
  def document_type_label(type) do
    case type do
      :manual -> "Manual"
      :drawing -> "Drawing"
      :specification -> "Specification"
      :procedure -> "Procedure"
      :work_instruction -> "Work Instruction"
      :certificate -> "Certificate"
      :calibration -> "Calibration"
      :warranty -> "Warranty"
      :other -> "Other"
      _ -> to_string(type)
    end
  end

  def document_type_icon(type) do
    case type do
      :manual -> "book-open"
      :drawing -> "document-text"
      :specification -> "clipboard-list"
      :procedure -> "clipboard-check"
      :work_instruction -> "clipboard-document-list"
      :certificate -> "badge-check"
      :calibration -> "adjustments"
      :warranty -> "shield-check"
      :other -> "document"
      _ -> "document"
    end
  end

  def document_type_color(type) do
    case type do
      :manual -> "bg-blue-100 text-blue-800"
      :drawing -> "bg-purple-100 text-purple-800"
      :specification -> "bg-green-100 text-green-800"
      :procedure -> "bg-yellow-100 text-yellow-800"
      :work_instruction -> "bg-orange-100 text-orange-800"
      :certificate -> "bg-indigo-100 text-indigo-800"
      :calibration -> "bg-pink-100 text-pink-800"
      :warranty -> "bg-teal-100 text-teal-800"
      :other -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from doc in query, where: doc.is_active == true
  end

  def for_asset(query \\ __MODULE__, asset_id) do
    from doc in query, where: doc.asset_id == ^asset_id
  end

  def for_pm_schedule(query \\ __MODULE__, schedule_id) do
    from doc in query, where: doc.pm_schedule_id == ^schedule_id
  end

  def for_work_order(query \\ __MODULE__, work_order_id) do
    from doc in query, where: doc.work_order_id == ^work_order_id
  end

  def by_type(query \\ __MODULE__, type) when type in @document_type_values do
    from doc in query, where: doc.document_type == ^type
  end
  def by_type(query, _), do: query

  def expiring_soon(query \\ __MODULE__, days \\ 30) do
    future = Date.add(Date.utc_today(), days)
    from doc in query,
      where: not is_nil(doc.expiry_date) and doc.expiry_date <= ^future and doc.is_active == true,
      order_by: [asc: doc.expiry_date]
  end

  def expired(query \\ __MODULE__) do
    today = Date.utc_today()
    from doc in query,
      where: not is_nil(doc.expiry_date) and doc.expiry_date < ^today and doc.is_active == true,
      order_by: [asc: doc.expiry_date]
  end

  def search_text(query \\ __MODULE__, term) when is_binary(term) and term != "" do
    term = "%" <> String.downcase(term) <> "%"
    from doc in query,
      where: ilike(doc.title, ^term) or
             ilike(doc.description, ^term) or
             ilike(doc.document_number, ^term)
  end
  def search_text(query, _), do: query
end
