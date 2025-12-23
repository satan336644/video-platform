$base = "http://localhost:4000/api"

# Login
$loginBody = @{ userId = "creator-phase12"; role = "creator" } | ConvertTo-Json
$tokenResponse = Invoke-RestMethod -Uri "$base/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $tokenResponse.token
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# Create video
$createBody = @{ title = "Phase 12 Manifest Test"; description = "real manifest URL"; creatorId = "creator-phase12" } | ConvertTo-Json
$video = Invoke-RestMethod -Uri "$base/videos" -Method POST -Headers $headers -Body $createBody
$vid = $video.id
Write-Host "Created video: $vid"

# Upload intent
$uploadIntent = Invoke-RestMethod -Uri "$base/videos/$vid/upload-intent" -Method POST -Headers $headers
Write-Host "Upload intent created"

# Process
$process = Invoke-RestMethod -Uri "$base/videos/$vid/process" -Method POST -Headers $headers
Write-Host "Processing started: $($process.message)"

# Wait for worker
Write-Host "Waiting 10 seconds for worker..."
Start-Sleep -Seconds 10

# Check status
$status = Invoke-RestMethod -Uri "$base/videos/$vid/status" -Method GET
Write-Host "Video status: $($status.status)"

# Get playback token
$playback = Invoke-RestMethod -Uri "$base/videos/$vid/playback-token" -Method POST
Write-Host "Got playback token"

# Call stream endpoint
$streamHeaders = @{ Authorization = "Bearer $($playback.playbackToken)" }
$stream = Invoke-RestMethod -Uri "$base/videos/$vid/stream" -Method GET -Headers $streamHeaders

Write-Host "`nStream endpoint response:"
$stream | ConvertTo-Json -Depth 5
