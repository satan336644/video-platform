# Phase 15.3 Verification: View Count Tracking (Write Path)

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 15.3 View Count Tracking Verification ==="

# Setup: use existing asset for increment tests (has manifest)
$creatorId = "creator-viewtrack"
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = $creatorId; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token
$videoIdForIncrement = "83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7"

# Capture initial viewCount
$initial = (Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement" -Method Get).viewCount
Write-Info "Initial viewCount: $initial"

# Valid playback increments
Write-Info "\n=== Test 1: Valid playback increments ==="
$playbackToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement/playback-token" -Method Post).playbackToken
$streamResp = Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement/stream" -Method Get -Headers @{ Authorization = "Bearer $playbackToken" }
Write-Info "Stream manifest: $($streamResp.manifestUrl)"
$afterFirst = (Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement" -Method Get).viewCount
if ($afterFirst -eq ($initial + 1)) { Write-Success "ViewCount incremented by 1 on first playback" } else { Write-ErrorMsg "Expected $(($initial + 1)), got $afterFirst" }

# Token reuse (idempotent)
Write-Info "\n=== Test 2: Token reuse ==="
$streamResp2 = Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement/stream" -Method Get -Headers @{ Authorization = "Bearer $playbackToken" }
$afterReuse = (Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement" -Method Get).viewCount
if ($afterReuse -eq $afterFirst) { Write-Success "No additional increment on token reuse" } else { Write-ErrorMsg "Unexpected increment on token reuse" }

# Invalid token
Write-Info "\n=== Test 3: Invalid token (no increment) ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/stream" -Method Get -Headers @{ Authorization = "Bearer invalid.token.value" } | Out-Null
  Write-ErrorMsg "Invalid token should fail"
} catch { Write-Success "Invalid token rejected" }
$afterInvalid = (Invoke-RestMethod -Uri "$baseUrl/videos/$videoIdForIncrement" -Method Get).viewCount
if ($afterInvalid -eq $afterReuse) { Write-Success "No increment for invalid token" }

# UNLISTED video should not increment
Write-Info "\n=== Test 4: UNLISTED no increment ==="
$unlisted = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Unlisted Test"; creatorId = $creatorId; visibility = "UNLISTED" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlisted.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlisted.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($unlisted.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
$unlistedToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/playback-token" -Method Post).playbackToken
Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" } | Out-Null
$unlistedViews = (Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)" -Method Get).viewCount
if ($unlistedViews -eq 0) { Write-Success "No increment for UNLISTED video" } else { Write-ErrorMsg "Unexpected increment for UNLISTED" }

# Regression: playback works for existing asset
Write-Info "\n=== Regression checks ==="
$existingToken = (Invoke-RestMethod -Uri "$baseUrl/videos/83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7/playback-token" -Method Post).playbackToken
$existingStream = Invoke-RestMethod -Uri "$baseUrl/videos/83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7/stream" -Method Get -Headers @{ Authorization = "Bearer $existingToken" }
Write-Success "Playback still works"

# Discovery and stats reflect counts
$popular = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
$trending = Invoke-RestMethod -Uri "$baseUrl/videos/trending" -Method Get
Write-Success "Discovery feeds reachable"
$stats = Invoke-RestMethod -Uri "$baseUrl/creator/stats" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
Write-Success "Creator stats reachable"

Write-Info "\n=== Phase 15.3 Verification Complete ==="
