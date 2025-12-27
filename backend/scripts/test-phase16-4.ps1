# Phase 16.4 Verification: Recommended Videos (Foundation)

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 16.4 Recommended Verification ==="

# Setup
$viewerToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "rec-viewer"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "rec-creator"; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token

# Reset history
Invoke-RestMethod -Uri "http://localhost:4000/test/users/rec-viewer/reset-history" -Method Post | Out-Null

# Create candidate videos with tags/categories
$v1 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "REC Cats"; creatorId = "rec-creator"; visibility = "PUBLIC"; category = "Pets"; tags = @("cats","cute") } | ConvertTo-Json) -ContentType "application/json"
$v2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "REC Dogs"; creatorId = "rec-creator"; visibility = "PUBLIC"; category = "Pets"; tags = @("dogs","cute") } | ConvertTo-Json) -ContentType "application/json"
$v3 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "REC Cooking"; creatorId = "rec-creator"; visibility = "PUBLIC"; category = "Food"; tags = @("cooking") } | ConvertTo-Json) -ContentType "application/json"
$v4 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "REC Private"; creatorId = "rec-creator"; visibility = "PRIVATE" } | ConvertTo-Json) -ContentType "application/json"

# Ready + manifest for public only
foreach ($v in @($v1,$v2,$v3)) {
  Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($v.id)/set-ready" -Method Post -Body (@{ } | ConvertTo-Json) -ContentType "application/json" | Out-Null
  Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($v.id)/set-manifest" -Method Post -Body (@{ manifestPath = "/processed/$($v.id)/index.m3u8" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
}

Write-Info "Created videos: $($v1.id), $($v2.id), $($v3.id); private: $($v4.id)"

# User likes and watches Pets content
Invoke-RestMethod -Uri "$baseUrl/videos/$($v1.id)/like" -Method Post -Headers @{ Authorization = "Bearer $viewerToken" } | Out-Null
$tok1 = (Invoke-RestMethod -Uri "$baseUrl/videos/$($v2.id)/playback-token" -Method Post -Headers @{ Authorization = "Bearer $viewerToken" }).playbackToken
Invoke-RestMethod -Uri "$baseUrl/videos/$($v2.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $tok1" } | Out-Null
Start-Sleep -Seconds 6
Invoke-RestMethod -Uri "$baseUrl/videos/$($v2.id)/stream" -Method Get -Headers @{ Authorization = "Bearer $tok1" } | Out-Null

# Fetch recommendations
Write-Info "\n=== Fetch recommendations (auth) ==="
$rec = Invoke-RestMethod -Uri "$baseUrl/videos/recommended?limit=10&page=1" -Method Get -Headers @{ Authorization = "Bearer $viewerToken" }

$ids = $rec.items | ForEach-Object { $_.video.id }
if (($ids -contains $v1.id)) { Write-Success "Relevant liked video returned" } else { Write-ErrorMsg "Missing relevant liked content" }
if (-not ($ids -contains $v2.id)) { Write-Success "Excludes recently watched" } else { Write-ErrorMsg "Included recently watched" }
if (-not ($ids -contains $v4.id)) { Write-Success "Excluded PRIVATE" } else { Write-ErrorMsg "PRIVATE included" }

# Ensure fallback without auth returns popular
Write-Info "\n=== Fallback (no auth) ==="
$recNoAuth = Invoke-RestMethod -Uri "$baseUrl/videos/recommended?limit=5&page=1" -Method Get
if ($recNoAuth.items.Count -gt 0) { Write-Success "Fallback returns popular" } else { Write-ErrorMsg "Fallback empty" }

Write-Info "\n=== Phase 16.4 Verification Complete ==="
