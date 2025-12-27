# Phase 15.4 Verification: Engagement Signals Hardening

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 15.4 Engagement Signals Verification ==="

# Setup: create a PUBLIC + READY video with manifest
$creatorId = "creator-engagement"
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = $creatorId; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token
$video = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Engagement Test"; creatorId = $creatorId; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($video.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$initial = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)" -Method Get).viewCount
Write-Info "Initial viewCount: $initial"

# Threshold check
Write-Info "\n=== Test 1: Thresholded increment (delayed) ==="
$token = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/playback-token" -Method Post).playbackToken
$stream1 = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token" }
$afterImmediate = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)" -Method Get).viewCount
if ($afterImmediate -eq $initial) { Write-Success "No increment before threshold" } else { Write-ErrorMsg "Unexpected increment before threshold" }
Start-Sleep -Seconds 6
$stream2 = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token" }
$afterDelay = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)" -Method Get).viewCount
if ($afterDelay -eq ($initial + 1)) { Write-Success "Incremented after threshold" } else { Write-ErrorMsg "Expected $(($initial + 1)), got $afterDelay" }

# Replay safety
Write-Info "\n=== Test 2: Token replay safety ==="
$stream3 = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token" }
$afterReplay = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)" -Method Get).viewCount
if ($afterReplay -eq $afterDelay) { Write-Success "No increment on token replay" } else { Write-ErrorMsg "Replay incorrectly incremented" }

# Expired token
Write-Info "\n=== Test 3: Expired token rejected ==="
$shortToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/playback-token?ttlSeconds=1" -Method Post).playbackToken
Start-Sleep -Seconds 2
try {
  Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $shortToken" } | Out-Null
  Write-ErrorMsg "Expired token should fail"
} catch { Write-Success "Expired token rejected" }
$afterExpired = (Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)" -Method Get).viewCount
if ($afterExpired -eq $afterReplay) { Write-Success "No increment from expired token" } else { Write-ErrorMsg "Expired token incremented viewCount" }

# UNLISTED no increment
Write-Info "\n=== Test 4: UNLISTED not counted ==="
$unlisted = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Unlisted Threshold"; creatorId = $creatorId; visibility = "UNLISTED" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlisted.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlisted.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($unlisted.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
$unlistedToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/playback-token" -Method Post).playbackToken
Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" } | Out-Null
Start-Sleep -Seconds 6
Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" } | Out-Null
$unlistedViews = (Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)" -Method Get).viewCount
if ($unlistedViews -eq 0) { Write-Success "UNLISTED view not counted" } else { Write-ErrorMsg "UNLISTED view incorrectly counted" }

# Regression
Write-Info "\n=== Regression checks ==="
$existingToken = (Invoke-RestMethod -Uri "$baseUrl/videos/83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7/playback-token" -Method Post).playbackToken
$existingStream = Invoke-RestMethod -Uri "$baseUrl/videos/83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7/stream" -Method Get -Headers @{ Authorization = "Bearer $existingToken" }
Write-Success "Playback still works"
$popular = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
$trending = Invoke-RestMethod -Uri "$baseUrl/videos/trending" -Method Get
Write-Success "Discovery feeds reachable"
$stats = Invoke-RestMethod -Uri "$baseUrl/creator/stats" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
Write-Success "Creator stats reachable"

Write-Info "\n=== Phase 15.4 Verification Complete ==="
