# Phoenix CMMS Development Environment Setup

## Required Tools Installation

### 1. Install Elixir and Erlang

#### Option A: Using Chocolatey (Recommended for Windows)
```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Elixir (includes Erlang)
choco install elixir
```

#### Option B: Direct Download
1. Download Erlang from: https://erlang.org/download/otp_versions_tree.html
2. Download Elixir from: https://elixir-lang.org/install.html#windows

### 2. Install Phoenix Framework
```powershell
# After Elixir is installed
mix archive.install hex phx_new
```

### 3. Install Node.js (for assets)
```powershell
# Using Chocolatey
choco install nodejs

# Or download from: https://nodejs.org/
```

## Manual Project Setup (If Elixir is not available)

Since we need to get started quickly, I'll create the project structure manually:

### Project Structure
```
shop1_cmms/
├── lib/
│   ├── shop1_cmms/
│   │   ├── accounts/
│   │   ├── assets/
│   │   ├── maintenance/
│   │   ├── tenants/
│   │   └── repo.ex
│   ├── shop1_cmms_web/
│   │   ├── components/
│   │   ├── controllers/
│   │   ├── live/
│   │   └── router.ex
│   └── shop1_cmms.ex
├── config/
├── test/
├── priv/
└── mix.exs
```

## Next Steps After Installation

1. **Run Phoenix generator:**
   ```bash
   mix phx.new shop1_cmms --live --no-ecto
   ```

2. **Configure database connection** to use existing Shop1 database

3. **Implement the schemas** from our integration guide

4. **Set up authentication** with existing users

5. **Build CMMS interfaces**

## Alternative: Development in VS Code

If Elixir installation is complex, we can:
1. Create the project files manually
2. Use VS Code with Elixir extensions
3. Focus on the business logic first
4. Set up the runtime environment later

Would you like me to proceed with manual project creation or would you prefer to install Elixir first?
