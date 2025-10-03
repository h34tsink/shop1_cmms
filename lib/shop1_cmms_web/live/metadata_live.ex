defmodule Shop1CmmsWeb.MetadataLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.Metadata
  alias Shop1Cmms.Metadata.{Manufacturer, Department, Supplier, PriorityCode, MaintenanceCategory, CustomField, PmTag}
  alias Shop1Cmms.Assets
  alias Shop1Cmms.Assets.{AssetType, AssetLocation}

  @metadata_types %{
    "manufacturers" => %{
      title: "Manufacturers",
      schema: Manufacturer,
      context_fn: :list_manufacturers,
      singular: "manufacturer"
    },
    "departments" => %{
      title: "Departments",
      schema: Department,
      context_fn: :list_departments,
      singular: "department"
    },
    "suppliers" => %{
      title: "Suppliers",
      schema: Supplier,
      context_fn: :list_suppliers,
      singular: "supplier"
    },
    "priority_codes" => %{
      title: "Priority Codes",
      schema: PriorityCode,
      context_fn: :list_priority_codes,
      singular: "priority_code"
    },
    "maintenance_categories" => %{
      title: "Maintenance Categories",
      schema: MaintenanceCategory,
      context_fn: :list_maintenance_categories,
      singular: "maintenance_category"
    },
    "custom_fields" => %{
      title: "Custom Fields",
      schema: CustomField,
      context_fn: :list_custom_fields,
      singular: "custom_field"
    },
    "asset_types" => %{
      title: "Asset Types",
      schema: AssetType,
      context_fn: :list_asset_types,
      singular: "asset_type"
    },
    "asset_locations" => %{
      title: "Asset Locations",
      schema: AssetLocation,
      context_fn: :list_asset_locations,
      singular: "asset_location"
    },
    "pm_tags" => %{
      title: "PM Tags (Skills, Tools, PPE)",
      schema: PmTag,
      context_fn: :list_pm_tags,
      singular: "pm_tag"
    }
  }

  @impl true
  def mount(%{"type" => type} = _params, _session, socket) when type in ["manufacturers", "departments", "suppliers", "priority_codes", "maintenance_categories", "custom_fields", "asset_types", "asset_locations", "pm_tags"] do
    tenant_id = socket.assigns.current_tenant.id

    {:ok,
     socket
     |> assign(:metadata_type, type)
     |> assign(:metadata_config, @metadata_types[type])
     |> assign(:search_query, "")
     |> assign(:show_modal, false)
     |> assign(:form_action, :new)
     |> assign(:selected_item, nil)
     |> assign(:tag_type_filter, "all")
     |> load_metadata_items(tenant_id)}
  end

  def mount(_params, _session, socket) do
    # Default to manufacturers if no type specified
    {:ok, push_navigate(socket, to: ~p"/configuration/manufacturers")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, socket.assigns.metadata_config.title)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New #{socket.assigns.metadata_config.singular}")
    |> assign(:show_modal, true)
    |> assign(:form_action, :new)
    |> assign(:selected_item, struct(socket.assigns.metadata_config.schema))
    |> assign_form()
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    item = get_metadata_item(socket.assigns.metadata_type, socket.assigns.current_tenant.id, id)

    socket
    |> assign(:page_title, "Edit #{socket.assigns.metadata_config.singular}")
    |> assign(:show_modal, true)
    |> assign(:form_action, :edit)
    |> assign(:selected_item, item)
    |> assign_form()
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    tenant_id = socket.assigns.current_tenant.id

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> load_metadata_items(tenant_id, query)}
  end

  def handle_event("new", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/configuration/#{socket.assigns.metadata_type}/new")}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/configuration/#{socket.assigns.metadata_type}/#{id}/edit")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    item = get_metadata_item(socket.assigns.metadata_type, socket.assigns.current_tenant.id, id)

    case delete_metadata_item(socket.assigns.metadata_type, item) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{socket.assigns.metadata_config.singular} deleted successfully")
         |> load_metadata_items(socket.assigns.current_tenant.id, socket.assigns.search_query)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete #{socket.assigns.metadata_config.singular}")}
    end
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/configuration/#{socket.assigns.metadata_type}")}
  end

  def handle_event("save", params, socket) do
    case socket.assigns.form_action do
      :new -> create_metadata_item(socket, params)
      :edit -> update_metadata_item(socket, params)
    end
  end

  defp create_metadata_item(socket, params) do
    type = socket.assigns.metadata_type
    tenant_id = socket.assigns.current_tenant.id

    attrs = Map.put(params[socket.assigns.metadata_config.singular], "tenant_id", tenant_id)

    case create_metadata_by_type(type, attrs) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{socket.assigns.metadata_config.singular} created successfully")
         |> push_patch(to: ~p"/configuration/#{type}")
         |> load_metadata_items(tenant_id, socket.assigns.search_query)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp create_metadata_by_type("manufacturers", attrs), do: Metadata.create_manufacturer(attrs)
  defp create_metadata_by_type("departments", attrs), do: Metadata.create_department(attrs)
  defp create_metadata_by_type("suppliers", attrs), do: Metadata.create_supplier(attrs)
  defp create_metadata_by_type("priority_codes", attrs), do: Metadata.create_priority_code(attrs)
  defp create_metadata_by_type("maintenance_categories", attrs), do: Metadata.create_maintenance_category(attrs)
  defp create_metadata_by_type("custom_fields", attrs), do: Metadata.create_custom_field(attrs)
  defp create_metadata_by_type("asset_types", attrs), do: Assets.create_asset_type(attrs)
  defp create_metadata_by_type("asset_locations", attrs), do: Assets.create_asset_location(attrs)

  defp update_metadata_item(socket, params) do
    type = socket.assigns.metadata_type
    item = socket.assigns.selected_item
    tenant_id = socket.assigns.current_tenant.id

    case update_metadata_by_type(type, item, params[socket.assigns.metadata_config.singular]) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{socket.assigns.metadata_config.singular} updated successfully")
         |> push_patch(to: ~p"/configuration/#{type}")
         |> load_metadata_items(tenant_id, socket.assigns.search_query)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset \\ nil) do
    changeset = changeset || change_metadata_by_type(socket.assigns.metadata_type, socket.assigns.selected_item || get_empty_item(socket.assigns.metadata_type))
    assign(socket, :form, to_form(changeset))
  end

  defp get_empty_item("manufacturers"), do: %Shop1Cmms.Metadata.Manufacturer{}
  defp get_empty_item("departments"), do: %Shop1Cmms.Metadata.Department{}
  defp get_empty_item("suppliers"), do: %Shop1Cmms.Metadata.Supplier{}
  defp get_empty_item("priority_codes"), do: %Shop1Cmms.Metadata.PriorityCode{}
  defp get_empty_item("maintenance_categories"), do: %Shop1Cmms.Metadata.MaintenanceCategory{}
  defp get_empty_item("custom_fields"), do: %Shop1Cmms.Metadata.CustomField{}
  defp get_empty_item("asset_types"), do: %Shop1Cmms.Assets.AssetType{}
  defp get_empty_item("asset_locations"), do: %Shop1Cmms.Assets.AssetLocation{}
  defp get_empty_item("pm_tags"), do: %Shop1Cmms.Metadata.PmTag{}

  defp load_metadata_items(socket, tenant_id, search_query \\ "") do
    opts = [active_only: true]
    opts = if search_query != "", do: Keyword.put(opts, :search, search_query), else: opts

    context_module = if socket.assigns.metadata_type in ["asset_types", "asset_locations"], do: Assets, else: Metadata
    items = apply(context_module, socket.assigns.metadata_config.context_fn, [tenant_id, opts])
    assign(socket, :items, items)
  end  # Context function helpers
  defp get_metadata_item("manufacturers", tenant_id, id), do: Metadata.get_manufacturer!(tenant_id, id)
  defp get_metadata_item("departments", tenant_id, id), do: Metadata.get_department!(tenant_id, id)
  defp get_metadata_item("suppliers", tenant_id, id), do: Metadata.get_supplier!(tenant_id, id)
  defp get_metadata_item("priority_codes", tenant_id, id), do: Metadata.get_priority_code!(tenant_id, id)
  defp get_metadata_item("maintenance_categories", tenant_id, id), do: Metadata.get_maintenance_category!(tenant_id, id)
  defp get_metadata_item("custom_fields", tenant_id, id), do: Metadata.get_custom_field!(tenant_id, id)
  defp get_metadata_item("asset_types", tenant_id, id), do: Assets.get_asset_type!(tenant_id, id)
  defp get_metadata_item("asset_locations", tenant_id, id), do: Assets.get_asset_location!(tenant_id, id)
  defp get_metadata_item("pm_tags", tenant_id, id), do: Metadata.get_pm_tag!(id)

  # These function definitions are moved to be grouped together at the end of the file



  # Form field rendering helper
  defp render_form_fields(f, metadata_type, config) do
    case metadata_type do
      type when type in ["manufacturers", "departments", "suppliers"] ->
        render_basic_fields(f, config)

      "priority_codes" ->
        render_priority_code_fields(f, config)

      "maintenance_categories" ->
        render_maintenance_category_fields(f, config)

      "custom_fields" ->
        render_custom_field_fields(f, config)

      "asset_types" ->
        render_asset_type_fields(f, config)

      "asset_locations" ->
        render_asset_location_fields(f, config)
      
      "pm_tags" ->
        render_pm_tag_fields(f, config)
    end
  end

  defp render_basic_fields(f, config) do
    assigns = %{f: f, config: config}

    case config.plural do
      "manufacturers" ->
        ~H"""
        <div>
          <.input field={@f[:name]} label="Name" required />
        </div>
        <div>
          <.input field={@f[:code]} label="Code" />
        </div>
        <div>
          <.input field={@f[:description]} label="Description" type="textarea" />
        </div>
        <div>
          <.input field={@f[:website]} label="Website" type="url" placeholder="https://example.com" />
        </div>
        <div>
          <.input field={@f[:contact_email]} label="Contact Email" type="email" />
        </div>
        <div>
          <.input field={@f[:contact_phone]} label="Contact Phone" type="tel" />
        </div>
        <div>
          <.input field={@f[:address]} label="Address" type="textarea" />
        </div>
        <div>
          <.input field={@f[:notes]} label="Notes" type="textarea" />
        </div>
        <div>
          <.input field={@f[:is_active]} label="Active" type="checkbox" />
        </div>
        """

      "departments" ->
        ~H"""
        <div>
          <.input field={@f[:name]} label="Name" required />
        </div>
        <div>
          <.input field={@f[:code]} label="Code" />
        </div>
        <div>
          <.input field={@f[:description]} label="Description" type="textarea" />
        </div>
        <div>
          <.input field={@f[:manager_name]} label="Manager Name" />
        </div>
        <div>
          <.input field={@f[:manager_email]} label="Manager Email" type="email" />
        </div>
        <div>
          <.input field={@f[:cost_center]} label="Cost Center" />
        </div>
        <div>
          <.input field={@f[:budget_code]} label="Budget Code" />
        </div>
        <div>
          <.input field={@f[:is_active]} label="Active" type="checkbox" />
        </div>
        """

      "suppliers" ->
        ~H"""
        <div>
          <.input field={@f[:name]} label="Name" required />
        </div>
        <div>
          <.input field={@f[:code]} label="Code" />
        </div>
        <div>
          <.input field={@f[:description]} label="Description" type="textarea" />
        </div>
        <div>
          <.input
            field={@f[:type]}
            label="Type"
            type="select"
            options={[
              {"Parts & Materials", "parts"},
              {"Services", "services"},
              {"Equipment", "equipment"},
              {"Maintenance", "maintenance"},
              {"Software", "software"},
              {"Other", "other"}
            ]}
          />
        </div>
        <div>
          <.input field={@f[:contact_name]} label="Contact Name" />
        </div>
        <div>
          <.input field={@f[:contact_email]} label="Contact Email" type="email" />
        </div>
        <div>
          <.input field={@f[:contact_phone]} label="Contact Phone" type="tel" />
        </div>
        <div>
          <.input field={@f[:address]} label="Address" type="textarea" />
        </div>
        <div>
          <.input field={@f[:website]} label="Website" type="url" placeholder="https://example.com" />
        </div>
        <div>
          <.input field={@f[:tax_id]} label="Tax ID" />
        </div>
        <div>
          <.input
            field={@f[:payment_terms]}
            label="Payment Terms"
            type="select"
            options={[
              {"Net 30", "net_30"},
              {"Net 15", "net_15"},
              {"Due on Receipt", "due_on_receipt"},
              {"Net 60", "net_60"},
              {"2/10 Net 30", "2_10_net_30"}
            ]}
          />
        </div>
        <div>
          <.input
            field={@f[:credit_rating]}
            label="Credit Rating"
            type="select"
            options={[
              {"Excellent", "excellent"},
              {"Good", "good"},
              {"Fair", "fair"},
              {"Poor", "poor"},
              {"Not Rated", "not_rated"}
            ]}
          />
        </div>
        <div>
          <.input field={@f[:notes]} label="Notes" type="textarea" />
        </div>
        <div>
          <.input field={@f[:is_active]} label="Active" type="checkbox" />
        </div>
        """

      "maintenance_categories" ->
        ~H"""
        <div>
          <.input field={@f[:name]} label="Name" required />
        </div>
        <div>
          <.input field={@f[:code]} label="Code" />
        </div>
        <div>
          <.input field={@f[:description]} label="Description" type="textarea" />
        </div>
        <div>
          <.input
            field={@f[:type]}
            label="Type"
            type="select"
            options={[
              {"Preventive", "preventive"},
              {"Corrective", "corrective"},
              {"Predictive", "predictive"},
              {"Emergency", "emergency"},
              {"Routine", "routine"}
            ]}
          />
        </div>
        <div>
          <.input field={@f[:default_frequency_days]} label="Default Frequency (Days)" type="number" min="1" />
        </div>
        <div>
          <.input field={@f[:requires_shutdown]} label="Requires Shutdown" type="checkbox" />
        </div>
        <div>
          <.input field={@f[:skill_requirements]} label="Skill Requirements" type="textarea" />
        </div>
        <div>
          <.input field={@f[:safety_requirements]} label="Safety Requirements" type="textarea" />
        </div>
        <div>
          <.input field={@f[:is_active]} label="Active" type="checkbox" />
        </div>
        """

      _ ->
        ~H"""
        <div>
          <.input field={@f[:name]} label="Name" required />
        </div>
        <div>
          <.input field={@f[:description]} label="Description" type="textarea" />
        </div>
        <div>
          <.input field={@f[:is_active]} label="Active" type="checkbox" />
        </div>
        """
    end
  end

  defp render_priority_code_fields(f, _config) do
    assigns = %{f: f}

    ~H"""
    <div>
      <.input field={@f[:name]} label="Name" required />
    </div>
    <div>
      <.input field={@f[:code]} label="Code" required />
    </div>
    <div>
      <.input field={@f[:description]} label="Description" type="textarea" />
    </div>
    <div>
      <.input field={@f[:level]} label="Priority Level (1-10)" type="number" min="1" max="10" />
    </div>
    <div>
      <.input field={@f[:color]} label="Color" type="color" />
    </div>
    <div>
      <.input field={@f[:sla_hours]} label="SLA Hours" type="number" min="0" />
    </div>
    <div>
      <.input field={@f[:auto_escalate]} label="Auto Escalate" type="checkbox" />
    </div>
    <div>
      <.input field={@f[:escalation_hours]} label="Escalation Hours" type="number" min="0" />
    </div>
    <div>
      <.input field={@f[:is_active]} label="Active" type="checkbox" />
    </div>
    """
  end

  defp render_maintenance_category_fields(f, _config) do
    assigns = %{f: f}

    ~H"""
    <div>
      <.input field={@f[:name]} label="Name" required />
    </div>
    <div>
      <.input field={@f[:code]} label="Code" />
    </div>
    <div>
      <.input field={@f[:description]} label="Description" type="textarea" />
    </div>
    <div>
      <.input
        field={@f[:type]}
        label="Type"
        type="select"
        options={[
          {"Preventive", "preventive"},
          {"Corrective", "corrective"},
          {"Predictive", "predictive"},
          {"Emergency", "emergency"},
          {"Routine", "routine"}
        ]}
      />
    </div>
    <div>
      <.input field={@f[:default_frequency_days]} label="Default Frequency (Days)" type="number" min="1" />
    </div>
    <div>
      <.input field={@f[:requires_shutdown]} label="Requires Shutdown" type="checkbox" />
    </div>
    <div>
      <.input field={@f[:skill_requirements]} label="Skill Requirements" type="textarea" />
    </div>
    <div>
      <.input field={@f[:safety_requirements]} label="Safety Requirements" type="textarea" />
    </div>
    <div>
      <.input field={@f[:is_active]} label="Active" type="checkbox" />
    </div>
    """
  end

  defp render_custom_field_fields(f, _config) do
    assigns = %{f: f}

    ~H"""
    <div>
      <.input field={@f[:field_name]} label="Field Name" required />
    </div>
    <div>
      <.input field={@f[:field_label]} label="Field Label" />
    </div>
    <div>
      <.input
        field={@f[:field_type]}
        label="Field Type"
        type="select"
        options={[
          {"Text", "text"},
          {"Number", "number"},
          {"Date", "date"},
          {"Boolean", "boolean"},
          {"Select", "select"},
          {"Multi Select", "multi_select"}
        ]}
      />
    </div>
    <div>
      <.input
        field={@f[:entity_type]}
        label="Entity Type"
        type="select"
        options={[
          {"Asset", "asset"},
          {"Work Order", "work_order"},
          {"User", "user"}
        ]}
      />
    </div>
    <div>
      <.input field={@f[:field_options]} label="Field Options (JSON)" type="textarea" placeholder={~s|{"options": ["Option 1", "Option 2"]}|} />
    </div>
    <div>
      <.input field={@f[:default_value]} label="Default Value" />
    </div>
    <div>
      <.input field={@f[:validation_rules]} label="Validation Rules (JSON)" type="textarea" placeholder={~s|{"min_length": 3, "max_length": 50}|} />
    </div>
    <div>
      <.input field={@f[:display_order]} label="Display Order" type="number" min="0" />
    </div>
    <div>
      <.input field={@f[:help_text]} label="Help Text" type="textarea" />
    </div>
    <div>
      <.input field={@f[:is_required]} label="Required" type="checkbox" />
    </div>
    <div>
      <.input field={@f[:is_active]} label="Active" type="checkbox" />
    </div>
    """
  end

  defp render_asset_type_fields(f, _config) do
    assigns = %{f: f}

    ~H"""
    <div>
      <.input field={@f[:name]} label="Name" required />
    </div>
    <div>
      <.input field={@f[:description]} label="Description" type="textarea" />
    </div>
    <div>
      <.input field={@f[:code]} label="Code" required />
    </div>
    <div>
      <.input
        field={@f[:category]}
        label="Category"
        type="select"
        options={[
          {"Equipment", "Equipment"},
          {"Tools", "Tools"},
          {"Vehicles", "Vehicles"},
          {"Infrastructure", "Infrastructure"},
          {"Facility", "Facility"},
          {"IT", "IT"},
          {"Other", "Other"}
        ]}
      />
    </div>
    <div>
      <.input field={@f[:icon]} label="Icon" />
    </div>
    <div>
      <.input field={@f[:color]} label="Color" type="color" />
    </div>
    <div>
      <.input field={@f[:has_meters]} label="Has Meters" type="checkbox" />
    </div>
    <div>
      <.input field={@f[:has_components]} label="Has Components" type="checkbox" />
    </div>
    <div>
      <.input field={@f[:default_pm_frequency]} label="Default PM Frequency (Days)" type="number" />
    </div>
    """
  end

  defp render_asset_location_fields(f, _config) do
    assigns = %{f: f}

    ~H"""
    <div>
      <.input field={@f[:name]} label="Name" required />
    </div>
    <div>
      <.input field={@f[:description]} label="Description" type="textarea" />
    </div>
    <div>
      <.input field={@f[:code]} label="Code" required />
    </div>
    <div>
      <.input field={@f[:address]} label="Address" type="textarea" />
    </div>
    <div>
      <.input field={@f[:gps_coordinates]} label="GPS Coordinates (lat,lng)" placeholder="40.7128,-74.0060" />
    </div>
    <div>
      <.input field={@f[:area_size]} label="Area Size" type="number" step="0.01" />
    </div>
    <div>
      <.input
        field={@f[:area_unit]}
        label="Area Unit"
        type="select"
        options={[
          {"Square Feet", "sqft"},
          {"Square Meters", "sqm"},
          {"Acres", "acres"},
          {"Hectares", "hectares"}
        ]}
      />
    </div>
    <div>
      <.input field={@f[:is_active]} label="Active" type="checkbox" />
    </div>
    """
  end

  # Context function helpers - grouped together for proper function arity organization

  defp update_metadata_by_type("manufacturers", item, attrs), do: Metadata.update_manufacturer(item, attrs)
  defp update_metadata_by_type("departments", item, attrs), do: Metadata.update_department(item, attrs)
  defp update_metadata_by_type("suppliers", item, attrs), do: Metadata.update_supplier(item, attrs)
  defp update_metadata_by_type("priority_codes", item, attrs), do: Metadata.update_priority_code(item, attrs)
  defp update_metadata_by_type("maintenance_categories", item, attrs), do: Metadata.update_maintenance_category(item, attrs)
  defp update_metadata_by_type("custom_fields", item, attrs), do: Metadata.update_custom_field(item, attrs)
  defp update_metadata_by_type("asset_types", item, attrs), do: Assets.update_asset_type(item, attrs)
  defp update_metadata_by_type("asset_locations", item, attrs), do: Assets.update_asset_location(item, attrs)
  defp update_metadata_by_type("pm_tags", item, attrs), do: Metadata.update_pm_tag(item, attrs)

  defp delete_metadata_item("manufacturers", item), do: Metadata.delete_manufacturer(item)
  defp delete_metadata_item("departments", item), do: Metadata.delete_department(item)
  defp delete_metadata_item("suppliers", item), do: Metadata.delete_supplier(item)
  defp delete_metadata_item("priority_codes", item), do: Metadata.delete_priority_code(item)
  defp delete_metadata_item("maintenance_categories", item), do: Metadata.delete_maintenance_category(item)
  defp delete_metadata_item("custom_fields", item), do: Metadata.delete_custom_field(item)
  defp delete_metadata_item("asset_types", item), do: Assets.delete_asset_type(item)
  defp delete_metadata_item("asset_locations", item), do: Assets.delete_asset_location(item)
  defp delete_metadata_item("pm_tags", item), do: Metadata.delete_pm_tag(item)

  defp change_metadata_by_type("manufacturers", item), do: Metadata.change_manufacturer(item)
  defp change_metadata_by_type("departments", item), do: Metadata.change_department(item)
  defp change_metadata_by_type("suppliers", item), do: Metadata.change_supplier(item)
  defp change_metadata_by_type("priority_codes", item), do: Metadata.change_priority_code(item)
  defp change_metadata_by_type("maintenance_categories", item), do: Metadata.change_maintenance_category(item)
  defp change_metadata_by_type("custom_fields", item), do: Metadata.change_custom_field(item)
  defp change_metadata_by_type("asset_types", item), do: Assets.change_asset_type(item)
  defp change_metadata_by_type("asset_locations", item), do: Assets.change_asset_location(item)
  defp change_metadata_by_type("pm_tags", item), do: Metadata.change_pm_tag(item)

  defp create_metadata_by_type("manufacturers", attrs), do: Metadata.create_manufacturer(attrs)
  defp create_metadata_by_type("departments", attrs), do: Metadata.create_department(attrs)
  defp create_metadata_by_type("suppliers", attrs), do: Metadata.create_supplier(attrs)
  defp create_metadata_by_type("priority_codes", attrs), do: Metadata.create_priority_code(attrs)
  defp create_metadata_by_type("maintenance_categories", attrs), do: Metadata.create_maintenance_category(attrs)
  defp create_metadata_by_type("custom_fields", attrs), do: Metadata.create_custom_field(attrs)
  defp create_metadata_by_type("asset_types", attrs), do: Assets.create_asset_type(attrs)
  defp create_metadata_by_type("asset_locations", attrs), do: Assets.create_asset_location(attrs)
  defp create_metadata_by_type("pm_tags", attrs), do: Metadata.create_pm_tag(attrs)

  defp render_pm_tag_fields(f, _config) do
    assigns = %{f: f}

    ~H"""
    <div>
      <.input field={@f[:name]} label="Tag Name" required placeholder="e.g., LOTO Certified, Torque Wrench, Safety Glasses" />
    </div>
    <div>
      <.input
        field={@f[:tag_type]}
        label="Tag Type"
        type="select"
        required
        options={[
          {"Skill", "skill"},
          {"Tool", "tool"},
          {"PPE", "ppe"}
        ]}
      />
    </div>
    <div>
      <.input field={@f[:description]} label="Description" type="textarea" placeholder="Optional description for this tag" />
    </div>
    <div class="text-sm text-gray-600">
      <p>Tags are used to categorize PM schedules by required skills, tools, and PPE.</p>
      <p class="mt-1">Usage count is automatically tracked when tags are used in PM schedules.</p>
    </div>
    """
  end
end
