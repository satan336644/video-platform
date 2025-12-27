# Phase 17.1 Verification: Notifications Foundation (Backend)

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 17.1 Notifications Verification ==="

# Login users
$viewerToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "notif-viewer"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "notif-creator"; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token

# Reset helper: clear creator notifications by deleting all for user (dev only) if available
# Not implemented, so create clean video and actions

# Create a PUBLIC video by creator
$video = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Notif Test"; creatorId = "notif-creator"; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($video.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

Write-Info "Created video: $($video.id)"

# Viewer likes the creator's video
Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Post -Headers @{ Authorization = "Bearer $viewerToken" } | Out-Null

# Fetch creator notifications
Write-Info "\n=== Fetch creator notifications ==="
$creatorNotifs = Invoke-RestMethod -Uri "$baseUrl/me/notifications?limit=10&page=1" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
$likeNotifs = $creatorNotifs.items | Where-Object { $_.type -eq "LIKE" -and $_.videoId -eq $video.id }
if ($likeNotifs.Count -ge 1) { Write-Success "Notification created on like" } else { Write-ErrorMsg "No like notification" }

# Summary line to reflect assertion result clearly
if ($likeNotifs.Count -ge 1) { Write-Info "Summary: Like notification created" } else { Write-Info "Summary: Like notification missing" }

# Ensure viewer does not receive self-notification
Write-Info "\n=== Ensure viewer has no self-notification ==="
$viewerNotifs = Invoke-RestMethod -Uri "$baseUrl/me/notifications" -Method Get -Headers @{ Authorization = "Bearer $viewerToken" }
if ($viewerNotifs.items.Count -eq 0) { Write-Success "Viewer does not receive own notification" } else { Write-ErrorMsg "Viewer received own notification" }

# Mark-as-read works
Write-Info "\n=== Mark as read ==="
$notifId = $likeNotifs[0].id
$mark = Invoke-RestMethod -Uri "$baseUrl/notifications/$notifId/read" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" }
if ($mark.notification.read -eq $true) { Write-Success "Mark-as-read works" } else { Write-ErrorMsg "Mark-as-read failed" }

# Pagination works (basic check)
Write-Info "\n=== Pagination ==="
$paginated = Invoke-RestMethod -Uri "$baseUrl/me/notifications?limit=1&page=1" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
if ($paginated.items.Count -eq 1) { Write-Success "Pagination works" } else { Write-ErrorMsg "Pagination failed" }

# Auth required
Write-Info "\n=== Auth required ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/me/notifications" -Method Get | Out-Null
  Write-ErrorMsg "Should require auth"
} catch { Write-Success "Auth enforced" }

Write-Info "\n=== Phase 17.1 Verification Complete ==="
