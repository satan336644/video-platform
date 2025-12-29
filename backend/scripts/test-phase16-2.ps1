# Phase 16.2 Verification: User Watch History

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 16.2 Watch History Verification ==="

# Setup: login users and create videos
$viewer1Token = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "viewer-history"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$viewer2Token = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "viewer2-history"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "creator-history"; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token

# Reset history for test users to avoid residue from prior runs
Invoke-RestMethod -Uri "http://localhost:4000/test/users/viewer-history/reset-history" -Method Post | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/users/viewer2-history/reset-history" -Method Post | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/users/creator-history/reset-history" -Method Post | Out-Null

# Create PUBLIC video
$publicVideo = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "History Test Video"; creatorId = "creator-history"; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($publicVideo.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($publicVideo.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($publicVideo.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

# Create UNLISTED video
$unlistedVideo = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Unlisted History Test"; creatorId = "creator-history"; visibility = "UNLISTED" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlistedVideo.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($unlistedVideo.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($unlistedVideo.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

Write-Info "Created PUBLIC video: $($publicVideo.id)"
Write-Info "Created UNLISTED video: $($unlistedVideo.id)"

# Test 1: History created after thresholded playback
Write-Info "`n=== Test 1: History entry created after threshold ==="
$token1 = (Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewer1Token" }).playbackToken
$stream1 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token1" }
$historyBefore = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $viewer1Token" }).history
if ($historyBefore.Count -eq 0) { Write-Success "No history before threshold" } else { Write-ErrorMsg "History created prematurely" }
Start-Sleep -Seconds 6
$stream2 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token1" }
$historyAfter = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $viewer1Token" }).history
if ($historyAfter.Count -eq 1 -and $historyAfter[0].videoId -eq $publicVideo.id) { Write-Success "History entry created after threshold" } else { Write-ErrorMsg "History not created correctly" }

# Test 2: Rewatch updates timestamp, not count
Write-Info "`n=== Test 2: Rewatch updates lastWatchedAt ==="
$firstWatch = $historyAfter[0].lastWatchedAt
Start-Sleep -Seconds 2
$token2 = (Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewer1Token" }).playbackToken
$stream3 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token2" }
Start-Sleep -Seconds 6
$stream4 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token2" }
$historyRewatch = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $viewer1Token" }).history
if ($historyRewatch.Count -eq 1) { Write-Success "Still one history entry (no duplicate)" } else { Write-ErrorMsg "Duplicate history entry created" }
if ([DateTime]$historyRewatch[0].lastWatchedAt -gt [DateTime]$firstWatch) { Write-Success "lastWatchedAt updated on rewatch" } else { Write-ErrorMsg "Timestamp not updated" }

# Test 3: Multiple videos in history, sorted by lastWatchedAt DESC
Write-Info "`n=== Test 3: Multiple videos sorted by recency ==="
$publicVideo2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Second Video"; creatorId = "creator-history"; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($publicVideo2.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($publicVideo2.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($publicVideo2.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
$token3 = (Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo2.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewer1Token" }).playbackToken
$stream5 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo2.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token3" }
Start-Sleep -Seconds 6
$stream6 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo2.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $token3" }
$historyMulti = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $viewer1Token" }).history
if ($historyMulti.Count -eq 2) { Write-Success "Two videos in history" } else { Write-ErrorMsg "Expected 2 videos, got $($historyMulti.Count)" }
if ($historyMulti[0].videoId -eq $publicVideo2.id) { Write-Success "Most recent video first" } else { Write-ErrorMsg "Not sorted by recency" }

# Test 4: Auth required
Write-Info "`n=== Test 4: Auth required for history ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get | Out-Null
  Write-ErrorMsg "Should require auth"
} catch { Write-Success "History requires auth" }

# Test 5: Per-user isolation
Write-Info "`n=== Test 5: Per-user history isolation ==="
$viewer2History = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $viewer2Token" }).history
if ($viewer2History.Count -eq 0) { Write-Success "Viewer2 has empty history" } else { Write-ErrorMsg "History leaked across users" }

# Test 6: UNLISTED videos not recorded
Write-Info "`n=== Test 6: UNLISTED videos excluded from history ==="
$unlistedToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$($unlistedVideo.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewer1Token" }).playbackToken
$streamUnlisted1 = Invoke-RestMethod -Uri "$baseUrl/videos/$($unlistedVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" }
Start-Sleep -Seconds 6
$streamUnlisted2 = Invoke-RestMethod -Uri "$baseUrl/videos/$($unlistedVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $unlistedToken" }
$historyUnlisted = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $viewer1Token" }).history
$unlistedInHistory = $historyUnlisted | Where-Object { $_.videoId -eq $unlistedVideo.id }
if ($null -eq $unlistedInHistory) { Write-Success "UNLISTED video not in history" } else { Write-ErrorMsg "UNLISTED video incorrectly recorded" }

# Test 7: Creator can have history
Write-Info "`n=== Test 7: Creator can have watch history ==="
$creatorPlayToken = (Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" }).playbackToken
$creatorStream1 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $creatorPlayToken" }
Start-Sleep -Seconds 6
$creatorStream2 = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $creatorPlayToken" }
$creatorHistory = (Invoke-RestMethod -Uri "$baseUrl/me/history" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }).history
if ($creatorHistory.Count -eq 1 -and $creatorHistory[0].videoId -eq $publicVideo.id) { Write-Success "Creator has watch history" } else { Write-ErrorMsg "Creator history not working" }

# Regression checks
Write-Info "`n=== Regression checks ==="
$videoDetail = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)" -Method Get
Write-Success "Video detail still works"
$likes = Invoke-RestMethod -Uri "$baseUrl/videos/$($publicVideo.id)/likes" -Method Get
Write-Success "Likes endpoint still works"
$popular = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
Write-Success "Discovery feeds still work"

Write-Info "`n=== Phase 16.2 Verification Complete ==="
