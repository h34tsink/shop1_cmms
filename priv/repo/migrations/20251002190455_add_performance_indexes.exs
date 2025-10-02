defmodule Shop1Cmms.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Indexes for pm_executions table to improve history query performance
    create index(:pm_executions, [:tenant_id, :status, :execution_date],
      name: :pm_executions_tenant_status_date_idx,
      comment: "Composite index for filtering completed PMs by tenant"
    )
    
    create index(:pm_executions, [:asset_id],
      name: :pm_executions_asset_id_idx,
      comment: "Index for joining with assets"
    )
    
    create index(:pm_executions, [:pm_schedule_id],
      name: :pm_executions_schedule_id_idx,
      comment: "Index for joining with pm_schedules"
    )
    
    create index(:pm_executions, [:completed_by_user_id],
      name: :pm_executions_user_id_idx,
      comment: "Index for joining with users"
    )

    # Indexes for work_orders table to improve history query performance
    create index(:work_orders, [:tenant_id, :status, :actual_start_date],
      name: :work_orders_tenant_status_date_idx,
      comment: "Composite index for filtering completed work orders by tenant"
    )
    
    create index(:work_orders, [:asset_id],
      name: :work_orders_asset_id_idx,
      comment: "Index for joining with assets"
    )
    
    create index(:work_orders, [:assigned_to],
      name: :work_orders_assigned_to_idx,
      comment: "Index for joining with users"
    )

    # Indexes for assets table to improve lookup performance
    create index(:assets, [:tenant_id],
      name: :assets_tenant_id_idx,
      comment: "Index for filtering assets by tenant"
    )

    # Indexes for pm_schedules table
    create index(:pm_schedules, [:tenant_id],
      name: :pm_schedules_tenant_id_idx,
      comment: "Index for filtering pm_schedules by tenant"
    )
    
    create index(:pm_schedules, [:asset_id],
      name: :pm_schedules_asset_id_idx,
      comment: "Index for joining with assets"
    )

    # Indexes for users table
    create index(:users, [:id],
      name: :users_id_idx,
      comment: "Index for user lookups"
    )
  end
end
