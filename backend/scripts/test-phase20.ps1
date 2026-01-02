$baseUrl = "http://localhost:4000/api"

Write-Host "`n=== Phase 20: Creator Analytics Tests ===`n" -ForegroundColor Cyan

# Setup: Login as creator
Write-Host "Setup: Logging in as creator..." -ForegroundColor Yellow
try {
  $login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body '{"email":"creator1@example.com","password":"SecurePass123"}' -ContentType "application/json"
  $token = $login.accessToken
  $creatorId = $login.user.id
  Write-Host "[OK] Logged in as $($login.user.username)" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Login failed: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Setup: Get a test video
Write-Host "`nSetup: Getting test video..." -ForegroundColor Yellow
try {
  $videos = Invoke-RestMethod -Uri "$baseUrl/videos?limit=1" -Method Get
  if (!$videos -or $videos.Count -eq 0) {
    Write-Host "[FAIL] No videos found. Run create-test-videos.ps1 first." -ForegroundColor Red
    exit 1
  }
  $videoId = $videos[0].id
  Write-Host "[OK] Using video: $videoId" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Could not fetch videos: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Test 1: Start watch session (anonymous)
Write-Host "`nTest 1: Start watch session (anonymous user)" -ForegroundColor Yellow
try {
  $session = Invoke-RestMethod -Uri "$baseUrl/analytics/watch/start" -Method Post -Body "{`"videoId`":`"$videoId`"}" -ContentType "application/json"
  $sessionId = $session.sessionId
  Write-Host "[OK] Session started: $sessionId" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 2: End watch session
Write-Host "`nTest 2: End watch session (60% watched)" -ForegroundColor Yellow
Start-Sleep -Seconds 1
try {
  $endSession = Invoke-RestMethod -Uri "$baseUrl/analytics/watch/$sessionId/end" -Method Post -Body '{"watchDuration":45,"percentWatched":0.6}' -ContentType "application/json"
  Write-Host "[OK] Session ended, analytics updated" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 3: Start and complete authenticated watch session
Write-Host "`nTest 3: Start watch session (authenticated user)" -ForegroundColor Yellow
try {
  $authSession = Invoke-RestMethod -Uri "$baseUrl/analytics/watch/start" -Method Post `
    -Headers @{ Authorization = "Bearer $token" } `
    -Body "{`"videoId`":`"$videoId`"}" -ContentType "application/json"
  $authSessionId = $authSession.sessionId
  Write-Host "[OK] Authenticated session started: $authSessionId" -ForegroundColor Green
  
  Start-Sleep -Seconds 1
  Invoke-RestMethod -Uri "$baseUrl/analytics/watch/$authSessionId/end" -Method Post `
    -Headers @{ Authorization = "Bearer $token" } `
    -Body '{"watchDuration":75,"percentWatched":0.95}' -ContentType "application/json" | Out-Null
  Write-Host "[OK] Video completed (95% watched)" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 4: Get creator analytics
Write-Host "`nTest 4: Get creator analytics overview" -ForegroundColor Yellow
try {
  $analytics = Invoke-RestMethod -Uri "$baseUrl/creators/me/analytics" -Method Get `
    -Headers @{ Authorization = "Bearer $token" }
  Write-Host "[OK] Analytics retrieved:" -ForegroundColor Green
  Write-Host "  Total Videos: $($analytics.overview.totalVideos)" -ForegroundColor Gray
  Write-Host "  Total Views: $($analytics.overview.totalViews)" -ForegroundColor Gray
  Write-Host "  Total Watch Time: $($analytics.overview.totalWatchTime)s" -ForegroundColor Gray
  Write-Host "  Avg Engagement: $([math]::Round($analytics.overview.averageEngagement, 2))" -ForegroundColor Gray
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 5: Get video-specific analytics
Write-Host "`nTest 5: Get video-specific analytics" -ForegroundColor Yellow
try {
  $videoAnalytics = Invoke-RestMethod -Uri "$baseUrl/videos/$videoId/analytics" -Method Get `
    -Headers @{ Authorization = "Bearer $token" }
  Write-Host "[OK] Video analytics retrieved:" -ForegroundColor Green
  Write-Host "  Total Views: $($videoAnalytics.analytics.totalViews)" -ForegroundColor Gray
  Write-Host "  Avg Watch Time: $([math]::Round($videoAnalytics.analytics.averageWatchTime, 2))s" -ForegroundColor Gray
  Write-Host "  Completion Rate: $([math]::Round($videoAnalytics.analytics.completionRate * 100, 2))%" -ForegroundColor Gray
  Write-Host "  Engagement Score: $([math]::Round($videoAnalytics.analytics.engagementScore, 2))" -ForegroundColor Gray
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 6: Get leaderboard (by views)
Write-Host "`nTest 6: Get creator leaderboard (by views)" -ForegroundColor Yellow
try {
  $leaderboard = Invoke-RestMethod -Uri "$baseUrl/analytics/leaderboard?sortBy=views&limit=5" -Method Get
  Write-Host "[OK] Leaderboard retrieved ($($leaderboard.leaderboard.Count) creators):" -ForegroundColor Green
  $leaderboard.leaderboard | ForEach-Object {
    Write-Host "  #$($_.rank) $($_.creator.username): $($_.stats.totalViews) views" -ForegroundColor Gray
  }
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 7: Get leaderboard (by engagement)
Write-Host "`nTest 7: Get leaderboard (by engagement)" -ForegroundColor Yellow
try {
  $engagementBoard = Invoke-RestMethod -Uri "$baseUrl/analytics/leaderboard?sortBy=engagement&limit=5" -Method Get
  Write-Host "[OK] Engagement leaderboard retrieved ($($engagementBoard.leaderboard.Count) creators)" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}

# Test 8: Non-creator cannot access creator analytics
Write-Host "`nTest 8: Non-creator access restriction (expect 403)" -ForegroundColor Yellow
try {
  $viewerLogin = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body '{"email":"viewer1@example.com","password":"ViewerPass789"}' -ContentType "application/json"
  
  Invoke-RestMethod -Uri "$baseUrl/creators/me/analytics" -Method Get `
    -Headers @{ Authorization = "Bearer $($viewerLogin.accessToken)" } -ErrorAction Stop
  Write-Host "[FAIL] Should have rejected viewer" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.Value__
  if ($code -eq 403) {
    Write-Host "[OK] Correctly rejected non-creator (403)" -ForegroundColor Green
  } else {
    Write-Host "[WARN] Expected 403, got $code" -ForegroundColor Yellow
  }
}

Write-Host "`n=== All Phase 20 Tests Completed ===`n" -ForegroundColor Cyan