# Phase 16.3 Verification: Continue Watching Feed

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 16.3 Continue Watching Verification ==="

# Setup: login users and create videos
$viewerToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "cw-viewer"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "cw-creator"; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token

# Reset any prior history for clean runs
Invoke-RestMethod -Uri "http://localhost:4000/test/users/cw-viewer/reset-history" -Method Post | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/users/cw-creator/reset-history" -Method Post | Out-Null

# Create videos
$public1 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "CW Public 1"; creatorId = "cw-creator"; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($public1.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($public1.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($public1.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$public2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "CW Public 2"; creatorId = "cw-creator"; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($public2.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($public2.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($public2.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

$unlisted = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "CW Unlisted"; creatorId = "cw-creator"; visibility = "UNLISTED" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlisted.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlisted.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($unlisted.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

Write-Info "Created PUBLIC videos: $($public1.id), $($public2.id)"
Write-Info "Created UNLISTED video: $($unlisted.id)"

# Create watch history via thresholded playback
$token1 = (Invoke-RestMethod -Uri "$baseUrl/videos/$($public1.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewerToken" }).playbackToken
Invoke-RestMethod -Uri "$baseUrl/videos/$($public1.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token1" } | Out-Null
Start-Sleep -Seconds 6
Invoke-RestMethod -Uri "$baseUrl/videos/$($public1.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token1" } | Out-Null

$token2 = (Invoke-RestMethod -Uri "$baseUrl/videos/$($public2.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewerToken" }).playbackToken
Invoke-RestMethod -Uri "$baseUrl/videos/$($public2.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token2" } | Out-Null
Start-Sleep -Seconds 6
Invoke-RestMethod -Uri "$baseUrl/videos/$($public2.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token2" } | Out-Null

# Unlisted watch should not appear
$unlistedToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewerToken" }).playbackToken
Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" } | Out-Null
Start-Sleep -Seconds 6
Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" } | Out-Null

# Fetch continue watching
Write-Info "\n=== Fetch continue watching ==="
$cw = Invoke-RestMethod -Uri "$baseUrl/me/continue-watching?limit=10&page=1" -Method Get -Headers @{ Authorization = "Bearer $viewerToken" }

if ($cw.items.Count -eq 2) { Write-Success "Returned only watched videos" } else { Write-ErrorMsg "Expected 2 items, got $($cw.items.Count)" }
if ($cw.items[0].videoId -eq $public2.id) { Write-Success "Sorted by lastWatchedAt DESC" } else { Write-ErrorMsg "Sorting incorrect" }
$unlistedFound = $cw.items | Where-Object { $_.videoId -eq $unlisted.id }
if ($null -eq $unlistedFound) { Write-Success "UNLISTED excluded" } else { Write-ErrorMsg "UNLISTED present in feed" }

# Auth enforcement
Write-Info "\n=== Auth enforcement ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/me/continue-watching" -Method Get | Out-Null
  Write-ErrorMsg "Should require auth"
} catch { Write-Success "Auth required" }

Write-Info "\n=== Phase 16.3 Verification Complete ==="
