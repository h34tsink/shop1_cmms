# Shop1 CMMS Setup Guide

## Prerequisites Installation

### 1. Install Elixir and Phoenix Framework

**Option A: Using Chocolatey (Recommended for Windows)**
```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Elixir (includes Erlang)
choco install elixir

# Refresh environment variables
refreshenv
```

**Option B: Manual Installation**
1. Download and install Erlang from: https://github.com/erlang/otp/releases
2. Download and install Elixir from: https://elixir-lang.org/install.html#windows

### 2. Install Phoenix Framework
```powershell
mix archive.install hex phx_new
```

### 3. Verify PostgreSQL (should be running on localhost:5433)
```powershell
# Test connection
psql -h localhost -p 5433 -U postgres
```

## Project Creation Steps

### 1. Create Phoenix Project
```powershell
cd c:\working_copy\shop1-stator
mix phx.new shop1_cmms --database postgresql --live
cd shop1_cmms
```

### 2. Configure Database
Edit `config/dev.exs` and update database configuration:
```elixir
config :shop1_cmms, Shop1Cmms.Repo,
  username: "postgres",
  password: "postgres",  # update with your password
  hostname: "localhost",
  port: 5433,
  database: "shop1_cmms_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### 3. Create Database and Run Migrations
```powershell
mix ecto.create
mix ecto.migrate
```

### 4. Install Dependencies
Add to `mix.exs` dependencies:
```elixir
{:oban, "~> 2.18"},
{:argon2_elixir, "~> 3.0"},
{:ex_audit, "~> 0.9"},
{:nimble_csv, "~> 1.1"},
{:timex, "~> 3.7"}
```

Then run:
```powershell
mix deps.get
```

### 5. Generate Authentication
```powershell
mix phx.gen.auth Accounts User users
mix ecto.migrate
```

## Next Steps
Once the basic setup is complete, proceed with the multi-tenant schema setup and PM scheduling implementation.
