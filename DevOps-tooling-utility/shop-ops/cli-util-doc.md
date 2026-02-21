# shop-ops CLI Utility

`shop-ops` is a specialized Go-based CLI tool designed to simplify operational tasks for the ShopMicro-Production project.

## Commands

### 1. `validate`
Performs a health check across all local services to ensure the environment is ready for operation.

**Usage:**
```powershell
./devops/shop-ops/shop-ops.exe validate
```

**Checks:**
- Frontend (Port 3000)
- Backend (Port 3001)
- ML Service (Port 5000)

---

### 2. `collect`
Automates the collection of logs and system status. Useful for gathering evidence for grading or debugging.

**Usage:**
```powershell
./devops/shop-ops/shop-ops.exe collect
```

**Collected Evidence:**
- `docker compose ps` status
- `docker compose logs` (last 100 lines)
- System summary with timestamp

All artifacts are saved in the `./grading-evidence/` directory.

---

## Building from Source

If you need to recompile the tool:

1. Ensure Go is installed.
2. Run the build command:
```powershell
go build -o shop-ops.exe devops/shop-ops/main.go
```
