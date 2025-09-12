defmodule Shop1Cmms.WorkOrders do
  @moduledoc """
  The WorkOrders context.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.WorkOrders.WorkOrder

  @doc """
  Returns the list of work_orders for a given tenant.
  """
  def list_work_orders(tenant_id, opts \\ []) do
    WorkOrder
    |> where([wo], wo.tenant_id == ^tenant_id)
    |> maybe_preload(opts)
    |> apply_filters(opts)
    |> apply_sorting(opts)
    |> Repo.all()
  end

  @doc """
  Returns the list of work_orders with detailed associations.
  """
  def list_work_orders_with_details(tenant_id, opts \\ []) do
    opts = Keyword.put(opts, :preload, [:asset])
    list_work_orders(tenant_id, opts)
  end

  @doc """
  Gets a single work_order.
  """
  def get_work_order!(id, tenant_id) do
    WorkOrder
    |> where([wo], wo.id == ^id and wo.tenant_id == ^tenant_id)
    |> Repo.one!()
  end

  @doc """
  Gets a single work_order with preloaded associations.
  """
  def get_work_order_with_details!(id, tenant_id) do
    WorkOrder
    |> where([wo], wo.id == ^id and wo.tenant_id == ^tenant_id)
    |> preload([:asset])
    |> Repo.one!()
  end

  @doc """
  Returns work orders for a specific asset.
  """
  def list_work_orders_for_asset(asset_id, tenant_id) do
    WorkOrder
    |> where([wo], wo.asset_id == ^asset_id and wo.tenant_id == ^tenant_id)
    |> order_by([wo], desc: wo.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns maintenance history (completed work orders) for an asset.
  """
  def get_maintenance_history(asset_id, tenant_id) do
    WorkOrder
    |> where([wo], wo.asset_id == ^asset_id and wo.tenant_id == ^tenant_id and wo.status == :completed)
    |> where([wo], not is_nil(wo.completed_at))
    |> order_by([wo], desc: wo.completed_at)
    |> select([wo], %{
      id: wo.id,
      title: wo.title,
      description: wo.description,
      completed_at: wo.completed_at,
      type: wo.work_type
    })
    |> Repo.all()
  end

  @doc """
  Creates a work_order.
  """
  def create_work_order(attrs \\ %{}) do
    attrs = Map.put_new(attrs, "work_order_number", generate_work_order_number(attrs["tenant_id"]))
    attrs = Map.put_new(attrs, "requested_date", DateTime.utc_now())

    %WorkOrder{}
    |> WorkOrder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a work_order.
  """
  def update_work_order(%WorkOrder{} = work_order, attrs) do
    work_order
    |> WorkOrder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a work_order.
  """
  def delete_work_order(%WorkOrder{} = work_order) do
    Repo.delete(work_order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking work_order changes.
  """
  def change_work_order(%WorkOrder{} = work_order, attrs \\ %{}) do
    WorkOrder.changeset(work_order, attrs)
  end

  # Private helper functions

  defp maybe_preload(query, opts) do
    case Keyword.get(opts, :preload) do
      nil -> query
      preloads -> preload(query, ^preloads)
    end
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, status}, acc -> WorkOrder.by_status(acc, status)
      {:priority, priority}, acc -> WorkOrder.by_priority(acc, priority)
      {:type, type}, acc -> WorkOrder.by_type(acc, type)
      {:assigned_to, user_id}, acc -> WorkOrder.by_assigned_to(acc, user_id)
      {:asset_id, asset_id}, acc -> WorkOrder.by_asset(acc, asset_id)
      {:search, term}, acc -> WorkOrder.search_text(acc, term)
      {:overdue, true}, acc -> WorkOrder.overdue(acc)
      {:due_soon, hours}, acc -> WorkOrder.due_soon(acc, hours)
      _, acc -> acc
    end)
  end

  defp apply_sorting(query, opts) do
    case Keyword.get(opts, :sort_by) do
      :due_date -> order_by(query, [wo], asc: wo.due_date, desc: wo.inserted_at)
      :priority -> order_by(query, [wo], desc: wo.priority, desc: wo.inserted_at)
      :status -> order_by(query, [wo], asc: wo.status, desc: wo.inserted_at)
      :work_order_number -> order_by(query, [wo], asc: wo.work_order_number)
      _ -> order_by(query, [wo], desc: wo.inserted_at)
    end
  end

  defp generate_work_order_number(tenant_id) when is_integer(tenant_id) do
    # Get the next work order number for this tenant
    prefix = "WO"
    date_part = Date.utc_today() |> to_string() |> String.replace("-", "")

    # Get count of work orders created today for this tenant
    today_start = Date.utc_today() |> DateTime.new!(~T[00:00:00])
    today_end = Date.utc_today() |> DateTime.new!(~T[23:59:59])

    count = WorkOrder
    |> where([wo], wo.tenant_id == ^tenant_id)
    |> where([wo], wo.inserted_at >= ^today_start and wo.inserted_at <= ^today_end)
    |> Repo.aggregate(:count, :id)

    sequence = String.pad_leading("#{count + 1}", 3, "0")

    "#{prefix}#{date_part}#{sequence}"
  end

  defp generate_work_order_number(_), do: "WO#{System.unique_integer([:positive])}"

  # Analytics and reporting functions

  @doc """
  Get work order statistics for a tenant.
  """
  def get_work_order_stats(tenant_id) do
    base_query = from(wo in WorkOrder, where: wo.tenant_id == ^tenant_id)

    %{
      total: Repo.aggregate(base_query, :count, :id),
      by_status: get_stats_by_field(base_query, :status),
      by_priority: get_stats_by_field(base_query, :priority),
      by_type: get_stats_by_field(base_query, :type),
      overdue: Repo.aggregate(WorkOrder.overdue(base_query), :count, :id),
      due_soon: Repo.aggregate(WorkOrder.due_soon(base_query), :count, :id)
    }
  end

  defp get_stats_by_field(query, field) do
    query
    |> group_by([wo], field(wo, ^field))
    |> select([wo], {field(wo, ^field), count(wo.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Get work orders assigned to a specific user.
  """
  def get_user_work_orders(user_id, tenant_id, opts \\ []) do
    list_work_orders(tenant_id, Keyword.put(opts, :assigned_to, user_id))
  end

  @doc """
  Get overdue work orders for a tenant.
  """
  def get_overdue_work_orders(tenant_id, opts \\ []) do
    list_work_orders(tenant_id, Keyword.put(opts, :overdue, true))
  end

  @doc """
  Get work orders due soon for a tenant.
  """
  def get_due_soon_work_orders(tenant_id, hours \\ 24, opts \\ []) do
    list_work_orders(tenant_id, Keyword.put(opts, :due_soon, hours))
  end

  @doc """
  Assign a work order to a user.
  """
  def assign_work_order(%WorkOrder{} = work_order, user_id, assigned_by_user_id) do
    attrs = %{
      assigned_to: user_id,
      updated_by: assigned_by_user_id,
      status: if(work_order.status == :open, do: :assigned, else: work_order.status)
    }

    update_work_order(work_order, attrs)
  end

  @doc """
  Start work on a work order.
  """
  def start_work_order(%WorkOrder{} = work_order, user_id) do
    attrs = %{
      status: :in_progress,
      actual_start_date: DateTime.utc_now(),
      updated_by: user_id
    }

    update_work_order(work_order, attrs)
  end

  @doc """
  Complete a work order.
  """
  def complete_work_order(%WorkOrder{} = work_order, completion_attrs, user_id) do
    attrs = Map.merge(completion_attrs, %{
      status: :completed,
      actual_end_date: DateTime.utc_now(),
      updated_by: user_id
    })

    update_work_order(work_order, attrs)
  end

  @doc """
  Put work order on hold.
  """
  def hold_work_order(%WorkOrder{} = work_order, reason, user_id) do
    attrs = %{
      status: :on_hold,
      completion_notes: reason,
      updated_by: user_id
    }

    update_work_order(work_order, attrs)
  end

  @doc """
  Cancel a work order.
  """
  def cancel_work_order(%WorkOrder{} = work_order, reason, user_id) do
    attrs = %{
      status: :cancelled,
      completion_notes: reason,
      updated_by: user_id
    }

    update_work_order(work_order, attrs)
  end
end
