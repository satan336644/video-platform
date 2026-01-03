$baseUrl = "http://localhost:4000/api"
Write-Host "`n=== Phase 21: Content Moderation Tests ===`n" -ForegroundColor Cyan

# Admin login
Write-Host "Setup: Logging in as admin..." -ForegroundColor Yellow
try {
  $admin = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
    email = "admin@example.com"
    password = "AdminPass999"
  } | ConvertTo-Json) -ContentType "application/json"
  $adminToken = $admin.accessToken
  Write-Host "[OK] Logged in as admin" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Admin login failed: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# User login
Write-Host "Setup: Logging in as user..." -ForegroundColor Yellow
try {
  $user = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
    email = "viewer1@example.com"
    password = "ViewerPass789"
  } | ConvertTo-Json) -ContentType "application/json"
  $userToken = $user.accessToken
  Write-Host "[OK] Logged in as user" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] User login failed: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Test 1: Moderation stats
Write-Host "`nTest 1: Get moderation stats (admin only)" -ForegroundColor Yellow
try {
  $stats = Invoke-RestMethod -Uri "$baseUrl/admin/moderation/stats" -Method Get -Headers @{ Authorization = "Bearer $adminToken" }
  Write-Host "[OK] Stats retrieved:" -ForegroundColor Green
  Write-Host "  Pending Videos: $($stats.pendingVideos)" -ForegroundColor Gray
  Write-Host "  Flagged Videos: $($stats.flaggedVideos)" -ForegroundColor Gray
  Write-Host "  Pending Reports: $($stats.pendingReports)" -ForegroundColor Gray
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Pending videos queue
Write-Host "`nTest 2: Get pending videos queue" -ForegroundColor Yellow
$testVideoId = $null
try {
  $pending = Invoke-RestMethod -Uri "$baseUrl/admin/moderation/pending?page=1&limit=5" -Method Get -Headers @{ Authorization = "Bearer $adminToken" }
  Write-Host "[OK] Found $($pending.pagination.total) pending videos" -ForegroundColor Green
  if ($pending.videos.Count -gt 0) {
    $testVideoId = $pending.videos[0].id
    Write-Host "  Will use video: $testVideoId for testing" -ForegroundColor Gray
  }
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Approve a video
if ($testVideoId) {
  Write-Host "`nTest 3: Approve video" -ForegroundColor Yellow
  try {
    Invoke-RestMethod -Uri "$baseUrl/admin/moderation/videos/$testVideoId/approve" -Method Post `
      -Headers @{ Authorization = "Bearer $adminToken" } `
      -Body (@{ notes = "Looks good" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
    Write-Host "[OK] Video approved" -ForegroundColor Green
  } catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  }
}

# Test 4: User reports video
Write-Host "`nTest 4: User reports video" -ForegroundColor Yellow
$reportVideoId = $null
$testReportId = $null
try {
  $videos = Invoke-RestMethod -Uri "$baseUrl/videos?limit=2" -Method Get
  if ($videos -and $videos.Count -gt 1) {
    $reportVideoId = $videos[1].id
    $report = Invoke-RestMethod -Uri "$baseUrl/reports" -Method Post `
      -Headers @{ Authorization = "Bearer $userToken" } `
      -Body (@{
        targetType = "VIDEO"
        targetId = $reportVideoId
        reason = "SPAM"
        description = "This is spam content"
      } | ConvertTo-Json) -ContentType "application/json"
    Write-Host "[OK] Report created: $($report.report.id)" -ForegroundColor Green
    $testReportId = $report.report.id
  }
} catch {
  Write-Host "[WARN] $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 5: Get reports (admin)
Write-Host "`nTest 5: Get reports list (admin)" -ForegroundColor Yellow
try {
  $reports = Invoke-RestMethod -Uri "$baseUrl/admin/moderation/reports?status=PENDING&page=1&limit=5" -Method Get `
    -Headers @{ Authorization = "Bearer $adminToken" }
  Write-Host "[OK] Found $($reports.pagination.total) pending reports" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Resolve report
if ($testReportId) {
  Write-Host "`nTest 6: Resolve report" -ForegroundColor Yellow
  try {
    Invoke-RestMethod -Uri "$baseUrl/admin/moderation/reports/$testReportId/resolve" -Method Post `
      -Headers @{ Authorization = "Bearer $adminToken" } `
      -Body (@{ resolution = "Reviewed and resolved" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
    Write-Host "[OK] Report resolved" -ForegroundColor Green
  } catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  }
}

# Test 7: Non-admin access restriction (expect 403)
Write-Host "`nTest 7: Non-admin access restriction (expect 403)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/admin/moderation/stats" -Method Get `
    -Headers @{ Authorization = "Bearer $userToken" } -ErrorAction Stop
  Write-Host "[FAIL] Should have rejected non-admin" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 403) {
    Write-Host "[OK] Correctly rejected non-admin (403)" -ForegroundColor Green
  } else {
    Write-Host "[WARN] Expected 403, got $code" -ForegroundColor Yellow
  }
}

# Test 8: Duplicate report prevention (expect 409)
if ($reportVideoId) {
  Write-Host "`nTest 8: Duplicate report prevention (expect 409)" -ForegroundColor Yellow
  try {
    Invoke-RestMethod -Uri "$baseUrl/reports" -Method Post `
      -Headers @{ Authorization = "Bearer $userToken" } `
      -Body (@{
        targetType = "VIDEO"
        targetId = $reportVideoId
        reason = "SPAM"
      } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
    Write-Host "[FAIL] Should have rejected duplicate report" -ForegroundColor Red
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 409) {
      Write-Host "[OK] Correctly rejected duplicate report (409)" -ForegroundColor Green
    } else {
      Write-Host "[WARN] Expected 409, got $code" -ForegroundColor Yellow
    }
  }
}

Write-Host "`n=== All Phase 21 Tests Completed ===`n" -ForegroundColor Cyan