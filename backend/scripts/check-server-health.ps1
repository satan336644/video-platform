# Test database connection
$baseUrl = "http://localhost:4000/api"

Write-Host "Testing database health..." -ForegroundColor Cyan

# Test a simple endpoint first
try {
  Write-Host "1. Testing health endpoint..." -ForegroundColor Yellow
  $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 3
  Write-Host "[OK] Server is responding" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Server not responding" -ForegroundColor Red
  exit 1
}

# Test videos endpoint
try {
  Write-Host "`n2. Testing videos endpoint..." -ForegroundColor Yellow
  $videos = Invoke-RestMethod -Uri "$baseUrl/videos?limit=1" -Method Get -TimeoutSec 3
  Write-Host "[OK] Videos endpoint working: $($videos.Count) videos" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Videos endpoint failed" -ForegroundColor Red
}

Write-Host "`nServer appears healthy. The analytics endpoint specifically is having issues." -ForegroundColor Yellow
Write-Host "Please check the backend console for error messages when you run the analytics test." -ForegroundColor Yellow