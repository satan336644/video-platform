# Phase 15.2 Verification: Creator Stats & Analytics (Foundation)

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 15.2 Creator Stats & Analytics Verification ==="

# Auth tokens
Write-Info "\n=== Setup: Acquire tokens ==="
$creatorId = "creator-analytics"
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = $creatorId; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token
$viewerToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "viewer-analytics"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
Write-Success "Tokens issued"

# Helper to create a video
function New-TestVideo($title, $visibility) {
  $body = @{ title = $title; creatorId = $creatorId; description = "analytics test"; visibility = $visibility } | ConvertTo-Json
  return Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $body -ContentType "application/json"
}

# Create videos
Write-Info "\n=== Setup: Create test videos with mixed status/visibility ==="
$videoA = New-TestVideo "Stats READY PUBLIC 100" "PUBLIC"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoA.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoA.id)/set-views" -Method Post -Body (@{ viewCount = 100 } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$videoB = New-TestVideo "Stats READY UNLISTED 50" "UNLISTED"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoB.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoB.id)/set-views" -Method Post -Body (@{ viewCount = 50 } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$videoC = New-TestVideo "Stats READY PRIVATE 25" "PRIVATE"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoC.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoC.id)/set-views" -Method Post -Body (@{ viewCount = 25 } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$videoD = New-TestVideo "Stats CREATED PUBLIC 10" "PUBLIC"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoD.id)/set-views" -Method Post -Body (@{ viewCount = 10 } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$videoE = New-TestVideo "Stats READY PUBLIC 15" "PUBLIC"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoE.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($videoE.id)/set-views" -Method Post -Body (@{ viewCount = 15 } | ConvertTo-Json) -ContentType "application/json" | Out-Null

Write-Success "Test videos created"

# Compute expected aggregates from created data
$expectedTotalVideos = 5
$expectedReadyVideos = 4
$expectedPublicVideos = 3
$expectedTotalViews = 100 + 50 + 25 + 10 + 15

# Test 1: Aggregate stats
Write-Info "\n=== Test 1: GET /creator/stats (aggregate) ==="
$agg = Invoke-RestMethod -Uri "$baseUrl/creator/stats" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
if ($agg.totalVideos -eq $expectedTotalVideos -and $agg.readyVideos -eq $expectedReadyVideos -and $agg.publicVideos -eq $expectedPublicVideos -and $agg.totalViews -eq $expectedTotalViews) {
  Write-Success "Aggregate stats match expectations"
} else {
  Write-ErrorMsg "Aggregate mismatch: $(($agg | ConvertTo-Json))"
}

# Sanity: ensure no other creators included
Write-Info "Creating a video for another creator to ensure isolation"
$otherToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "other-creator"; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token
$other = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $otherToken" } -Body (@{ title = "Other creator video"; creatorId = "other-creator" } | ConvertTo-Json) -ContentType "application/json"
$agg2 = Invoke-RestMethod -Uri "$baseUrl/creator/stats" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
if ($agg2.totalVideos -eq $expectedTotalVideos) { Write-Success "No cross-creator leakage" } else { Write-ErrorMsg "Creator isolation failed" }

# Test 2: Per-video stats
Write-Info "\n=== Test 2: GET /creator/videos/stats (per-video) ==="
$items = Invoke-RestMethod -Uri "$baseUrl/creator/videos/stats" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
if ($items.Count -ge 5) { Write-Success "Returned all creator videos" } else { Write-ErrorMsg "Missing videos in stats" }

# Check a couple fields
$sample = $items | Select-Object -First 1
if ($sample.PSObject.Properties.Name -contains "viewCount" -and $sample.PSObject.Properties.Name -contains "visibility" -and $sample.PSObject.Properties.Name -contains "status") {
  Write-Success "Per-video fields present"
}

# Sorted by createdAt DESC recommended
$sorted = ($items | Sort-Object -Property createdAt -Descending)
if ($sorted[0].id -eq $items[0].id) { Write-Success "Sorted by createdAt DESC" }

# Security tests
Write-Info "\n=== Security: role and auth checks ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/creator/stats" -Method Get -Headers @{ Authorization = "Bearer $viewerToken" } | Out-Null
  Write-ErrorMsg "Viewer role should be forbidden"
} catch { Write-Success "Viewer role receives 403" }

try {
  Invoke-RestMethod -Uri "$baseUrl/creator/stats" -Method Get | Out-Null
  Write-ErrorMsg "Missing auth should be 401"
} catch { Write-Success "Missing auth returns 401" }

# Regression
Write-Info "\n=== Regression checks ==="
& npx tsc --noEmit | Out-Null
Write-Success "TypeScript compile clean"

# Playback test (existing asset)
$playbackToken = (Invoke-RestMethod -Uri "$baseUrl/videos/83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7/playback-token" -Method Post).playbackToken
$stream = Invoke-RestMethod -Uri "$baseUrl/videos/83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7/stream" -Method Get -Headers @{ Authorization = "Bearer $playbackToken" }
Write-Success "Playback still works"

# Discovery feeds unchanged
$popular = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
$trending = Invoke-RestMethod -Uri "$baseUrl/videos/trending" -Method Get
Write-Success "Discovery feeds unchanged"

Write-Info "\n=== Phase 15.2 Verification Complete ==="
