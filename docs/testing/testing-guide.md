# Testing Guide

## Overview

Shop1 CMMS follows comprehensive testing practices to ensure reliability, maintainability, and quality. This guide covers testing strategies, patterns, and tools used throughout the project.

## Testing Philosophy

### Test-Driven Development (TDD)

We follow a test-first approach where possible:

1. **Write failing tests** for new features
2. **Implement minimal code** to make tests pass  
3. **Refactor** while keeping tests green
4. **Document** test cases and expected behavior

### Testing Pyramid

Our testing strategy follows the testing pyramid:

- **Unit Tests (70%)**: Test individual functions and modules
- **Integration Tests (20%)**: Test LiveView interactions and contexts
- **End-to-End Tests (10%)**: Test complete user workflows

## Test Structure

### Directory Organization

```text
test/
├── shop1_cmms/              # Context and schema tests
│   ├── assets_test.exs      # Assets context tests
│   ├── accounts_test.exs    # User management tests
│   └── work_orders_test.exs # Work order tests
├── shop1_cmms_web/          # Web layer tests
│   ├── live/                # LiveView tests
│   ├── controllers/         # Controller tests
│   └── components/          # Component tests
└── support/                 # Test utilities
    ├── fixtures.exs         # Test data factories
    ├── conn_case.ex        # Connection test helpers
    └── data_case.ex        # Database test helpers
```

### Test Categories

#### 1. Context Tests (Business Logic)

Test the core business logic in isolation:

```elixir
# test/shop1_cmms/assets_test.exs
defmodule Shop1Cmms.AssetsTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.Assets
  
  describe "list_assets/1" do
    test "returns assets for specific tenant" do
      tenant1 = tenant_fixture()
      tenant2 = tenant_fixture()
      
      asset1 = asset_fixture(tenant_id: tenant1.id)
      _asset2 = asset_fixture(tenant_id: tenant2.id)
      
      result = Assets.list_assets(tenant1.id)
      assert length(result) == 1
      assert hd(result).id == asset1.id
    end
    
    test "returns empty list for tenant with no assets" do
      tenant = tenant_fixture()
      assert Assets.list_assets(tenant.id) == []
    end
  end
  
  describe "create_asset/2" do
    test "creates asset with valid attributes" do
      tenant = tenant_fixture()
      attrs = valid_asset_attributes()
      
      assert {:ok, asset} = Assets.create_asset(tenant.id, attrs)
      assert asset.tenant_id == tenant.id
      assert asset.name == attrs.name
    end
    
    test "returns error with invalid attributes" do
      tenant = tenant_fixture()
      attrs = %{name: nil}
      
      assert {:error, changeset} = Assets.create_asset(tenant.id, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end
```

#### 2. LiveView Tests (UI Integration)

Test LiveView interactions and real-time features:

```elixir
# test/shop1_cmms_web/live/assets_live_test.exs
defmodule Shop1CmmsWeb.AssetsLiveTest do
  use Shop1CmmsWeb.ConnCase
  
  import Phoenix.LiveViewTest
  
  setup :register_and_log_in_user
  
  describe "Index page" do
    test "displays assets for current tenant", %{conn: conn, user: user} do
      tenant = user.current_tenant
      asset = asset_fixture(tenant_id: tenant.id)
      
      {:ok, _index_live, html} = live(conn, ~p"/assets")
      
      assert html =~ "Assets"
      assert html =~ asset.name
    end
    
    test "filters assets by status", %{conn: conn, user: user} do
      tenant = user.current_tenant
      active_asset = asset_fixture(tenant_id: tenant.id, status: "Active")
      inactive_asset = asset_fixture(tenant_id: tenant.id, status: "Inactive")
      
      {:ok, index_live, html} = live(conn, ~p"/assets")
      
      # Initially shows all assets
      assert html =~ active_asset.name
      assert html =~ inactive_asset.name
      
      # Filter by Active status
      index_live
      |> form("#filter-form")
      |> render_change(%{status: "Active"})
      
      html = render(index_live)
      assert html =~ active_asset.name
      refute html =~ inactive_asset.name
    end
    
    test "creates new asset", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")
      
      assert index_live |> element("a", "New Asset") |> render_click() =~
               "New Asset"
      
      assert_patch(index_live, ~p"/assets/new")
      
      assert index_live
             |> form("#asset-form", asset: invalid_asset_attributes())
             |> render_change() =~ "can&#39;t be blank"
      
      assert index_live
             |> form("#asset-form", asset: valid_asset_attributes())
             |> render_submit()
      
      assert_patch(index_live, ~p"/assets")
      
      html = render(index_live)
      assert html =~ "Asset created successfully"
    end
  end
end
```

#### 3. Schema Tests (Data Validation)

Test Ecto schemas and changesets:

```elixir
# test/shop1_cmms/assets/asset_test.exs
defmodule Shop1Cmms.Assets.AssetTest do
  use Shop1Cmms.DataCase
  
  alias Shop1Cmms.Assets.Asset
  
  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = valid_asset_attributes()
      changeset = Asset.changeset(%Asset{}, attrs)
      
      assert changeset.valid?
    end
    
    test "requires name" do
      attrs = valid_asset_attributes() |> Map.delete(:name)
      changeset = Asset.changeset(%Asset{}, attrs)
      
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end
    
    test "validates asset_code uniqueness per tenant" do
      tenant = tenant_fixture()
      existing_asset = asset_fixture(tenant_id: tenant.id, asset_code: "A001")
      
      attrs = valid_asset_attributes(asset_code: "A001")
      changeset = Asset.changeset(%Asset{tenant_id: tenant.id}, attrs)
      
      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).asset_code
    end
  end
end
```

## Testing Patterns

### 1. Multi-Tenancy Testing

Always test tenant isolation:

```elixir
test "only returns data for current tenant" do
  tenant1 = tenant_fixture()
  tenant2 = tenant_fixture() 
  
  asset1 = asset_fixture(tenant_id: tenant1.id)
  asset2 = asset_fixture(tenant_id: tenant2.id)
  
  # Should only return tenant1's data
  result = Assets.list_assets(tenant1.id)
  assert asset1 in result
  refute asset2 in result
end
```

### 2. Filter Testing

Comprehensive filtering logic tests:

```elixir
describe "filtering" do
  setup do
    tenant = tenant_fixture()
    
    assets = [
      asset_fixture(tenant_id: tenant.id, status: "Active", criticality: "High"),
      asset_fixture(tenant_id: tenant.id, status: "Inactive", criticality: "Low"),
      asset_fixture(tenant_id: tenant.id, status: "Active", criticality: "Medium")
    ]
    
    %{tenant: tenant, assets: assets}
  end
  
  test "filters by single criteria", %{tenant: tenant} do
    result = Assets.list_assets_filtered(tenant.id, %{status: "Active"})
    assert length(result) == 2
    assert Enum.all?(result, &(&1.status == "Active"))
  end
  
  test "filters by multiple criteria", %{tenant: tenant} do
    filters = %{status: "Active", criticality: "High"}
    result = Assets.list_assets_filtered(tenant.id, filters)
    
    assert length(result) == 1
    assert hd(result).status == "Active"
    assert hd(result).criticality == "High"
  end
  
  test "returns empty list when no matches", %{tenant: tenant} do
    result = Assets.list_assets_filtered(tenant.id, %{status: "Retired"})
    assert result == []
  end
end
```

### 3. Error Handling Tests

Test error conditions and edge cases:

```elixir
test "handles database errors gracefully" do
  # Mock database error
  expect(MockRepo, :all, fn _ -> {:error, :database_error} end)
  
  assert {:error, :database_error} = Assets.list_assets(1)
end

test "validates required associations" do
  attrs = valid_asset_attributes() |> Map.put(:manufacturer_id, 999)
  changeset = Asset.changeset(%Asset{}, attrs)
  
  assert {:error, changeset} = Repo.insert(changeset)
  assert "does not exist" in errors_on(changeset).manufacturer_id
end
```

## Test Coverage

### Current Coverage Status

- **Overall Coverage**: 85%
- **Context Tests**: 90% coverage
- **LiveView Tests**: 80% coverage  
- **Schema Tests**: 95% coverage

### Coverage Goals

- **Minimum Coverage**: 80% for all modules
- **Critical Paths**: 100% coverage for security and data integrity
- **New Features**: 90% coverage requirement

### Running Coverage Reports

```bash
# Generate coverage report
mix test --cover

# Generate HTML coverage report
mix test --cover --export-coverage default
mix test.coverage

# View coverage by file
mix test --cover --export-coverage default | grep -E "lib/.*\.ex"
```

## Testing Utilities

### Test Fixtures

Create reusable test data:

```elixir
# test/support/fixtures.exs
defmodule Shop1Cmms.Fixtures do
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "Test Tenant #{System.unique_integer()}",
        tenant_code: "T#{System.unique_integer()}"
      })
      |> Shop1Cmms.Accounts.create_tenant()
      
    tenant
  end
  
  def asset_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || tenant_fixture().id
    
    {:ok, asset} =
      attrs
      |> Enum.into(%{
        tenant_id: tenant_id,
        name: "Test Asset #{System.unique_integer()}",
        asset_code: "A#{System.unique_integer()}",
        status: "Active",
        criticality: "Medium"
      })
      |> Shop1Cmms.Assets.create_asset(tenant_id)
      
    asset
  end
end
```

### Custom Assertions

Create domain-specific assertions:

```elixir
# test/support/assertions.ex
defmodule Shop1Cmms.TestAssertions do
  import ExUnit.Assertions
  
  def assert_tenant_isolation(context_function, tenant1, tenant2) do
    # Create data for both tenants
    data1 = create_test_data(tenant1.id)
    data2 = create_test_data(tenant2.id)
    
    # Verify each tenant only sees their own data
    result1 = context_function.(tenant1.id)
    result2 = context_function.(tenant2.id)
    
    assert data1 in result1
    refute data2 in result1
    
    assert data2 in result2  
    refute data1 in result2
  end
end
```

## Performance Testing

### Load Testing

Test system performance under load:

```elixir
# test/shop1_cmms_web/performance_test.exs
defmodule Shop1CmmsWeb.PerformanceTest do
  use Shop1CmmsWeb.ConnCase
  
  @tag :performance
  test "assets page loads under 500ms", %{conn: conn} do
    tenant = tenant_fixture()
    # Create 1000 test assets
    1..1000 |> Enum.each(fn _ -> asset_fixture(tenant_id: tenant.id) end)
    
    {time_microseconds, _response} = :timer.tc(fn ->
      get(conn, ~p"/assets")
    end)
    
    time_milliseconds = time_microseconds / 1000
    assert time_milliseconds < 500, "Page load took #{time_milliseconds}ms"
  end
end
```

### Database Performance

Test query performance:

```elixir
test "list_assets query performance" do
  tenant = tenant_fixture()
  # Create large dataset
  1..10_000 |> Enum.each(fn _ -> asset_fixture(tenant_id: tenant.id) end)
  
  {time_microseconds, _result} = :timer.tc(fn ->
    Assets.list_assets(tenant.id)
  end)
  
  time_milliseconds = time_microseconds / 1000
  assert time_milliseconds < 100, "Query took #{time_milliseconds}ms"
end
```

## Continuous Integration

### GitHub Actions

Automated testing pipeline:

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: --health-cmd pg_isready --health-interval 10s
          
    steps:
      - uses: actions/checkout@v2
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: 1.15
          otp-version: 26
          
      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - run: mix test --cover
      - run: mix credo --strict
```

### Quality Gates

Required checks before deployment:

- **Test Coverage**: Minimum 80% overall
- **All Tests Pass**: Zero failing tests
- **Code Quality**: Credo analysis passes
- **Security**: No known vulnerabilities
- **Performance**: All performance tests under thresholds

## Best Practices

### Test Organization

1. **Group related tests** using `describe` blocks
2. **Use descriptive test names** that explain the expected behavior
3. **Follow AAA pattern**: Arrange, Act, Assert
4. **Keep tests focused** on single behaviors
5. **Use setup blocks** for common test data

### Test Maintenance

1. **Update tests** when requirements change
2. **Remove obsolete tests** for deprecated features
3. **Refactor tests** to reduce duplication
4. **Document complex test scenarios**
5. **Review test coverage** regularly

### Debugging Tests

```bash
# Run specific test
mix test test/shop1_cmms/assets_test.exs:25

# Run tests with detailed output
mix test --trace

# Run failed tests only
mix test --failed

# Run tests with debugging
mix test --verbose
```

---

**Note:** This document consolidates testing information from FILTERS_TESTING_COMPLETE_SUMMARY.md and other testing-related documentation files
