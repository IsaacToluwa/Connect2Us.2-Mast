# Simple Entity Framework Migration Test Script
param(
    [string]$ServerInstance = "(LocalDb)\MSSQLLocalDB",
    [string]$DatabaseName = "aspnet-Connect2Us.2-master-20231127012345"
)

Write-Host "=== Testing Entity Framework Migrations ===" -ForegroundColor Green
Write-Host "Database: $DatabaseName" -ForegroundColor Yellow
Write-Host ""

# Test 1: Run MigrationRunner
Write-Host "STEP 1: Running MigrationRunner..." -ForegroundColor Cyan
Push-Location ".\MigrationRunner"
dotnet build --configuration Release
if ($LASTEXITCODE -eq 0) {
    dotnet run --configuration Release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MigrationRunner completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ MigrationRunner failed!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ MigrationRunner build failed!" -ForegroundColor Red
}
Pop-Location

Write-Host ""

# Test 2: Check database connectivity
Write-Host "STEP 2: Testing database connectivity..." -ForegroundColor Cyan
$testQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"
$result = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $testQuery -h -1 -W
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database connectivity verified. Tables found: $result" -ForegroundColor Green
} else {
    Write-Host "❌ Database connectivity test failed!" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check key tables
Write-Host "STEP 3: Checking key tables..." -ForegroundColor Cyan
$tables = @("AspNetUsers", "AspNetRoles", "Categories", "Products", "Bookstores", "Customers")
foreach ($table in $tables) {
    $tableQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$table'"
    $tableExists = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $tableQuery -h -1 -W
    if ($tableExists -gt 0) {
        Write-Host "  ✅ Table $table exists" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Table $table missing!" -ForegroundColor Red
    }
}

Write-Host ""

# Test 4: Check seeded data
Write-Host "STEP 4: Checking seeded data..." -ForegroundColor Cyan

# Check admin user
$adminQuery = "SELECT COUNT(*) FROM AspNetUsers WHERE Email = 'olatunjitoluwanimi90@yahoo.com'"
$adminExists = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $adminQuery -h -1 -W
if ($adminExists -gt 0) {
    Write-Host "  ✅ Admin user exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ Admin user missing!" -ForegroundColor Red
}

# Check roles
$rolesQuery = "SELECT COUNT(*) FROM AspNetRoles WHERE Name IN ('Admin', 'Bookstore', 'Customer', 'DeliveryDriver')"
$rolesCount = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $rolesQuery -h -1 -W
if ($rolesCount -ge 4) {
    Write-Host "  ✅ All required roles exist" -ForegroundColor Green
} else {
    Write-Host "  ❌ Some roles missing! Found: $rolesCount" -ForegroundColor Red
}

# Check categories
$categoriesQuery = "SELECT COUNT(*) FROM Categories"
$categoriesCount = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $categoriesQuery -h -1 -W
if ($categoriesCount -gt 0) {
    Write-Host "  ✅ Categories seeded ($categoriesCount categories)" -ForegroundColor Green
} else {
    Write-Host "  ❌ No categories found!" -ForegroundColor Red
}

# Check products
$productsQuery = "SELECT COUNT(*) FROM Products"
$productsCount = sqlcmd -S "$ServerInstance" -d "$DatabaseName" -Q $productsQuery -h -1 -W
if ($productsCount -gt 0) {
    Write-Host "  ✅ Products seeded ($productsCount products)" -ForegroundColor Green
} else {
    Write-Host "  ❌ No products found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Migration Testing Complete ===" -ForegroundColor Green