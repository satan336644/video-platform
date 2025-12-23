Start-Sleep -Seconds 2
$base = "http://localhost:4000/api"

# Login
$loginBody = @{ userId = "creator-absolute"; role = "creator" } | ConvertTo-Json
$tokenResponse = Invoke-RestMethod -Uri "$base/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $tokenResponse.token
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# Create video
$createBody = @{ title = "Always Absolute URL"; description = "final polish"; creatorId = "creator-absolute" } | ConvertTo-Json
$video = Invoke-RestMethod -Uri "$base/videos" -Method POST -Headers $headers -Body $createBody
$vid = $video.id
Write-Host "Created: $vid" -ForegroundColor Green

# Upload intent and process
Invoke-RestMethod -Uri "$base/videos/$vid/upload-intent" -Method POST -Headers $headers | Out-Null
Invoke-RestMethod -Uri "$base/videos/$vid/process" -Method POST -Headers $headers | Out-Null
Write-Host "Processing... waiting 10s" -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Get playback token and stream
$playback = Invoke-RestMethod -Uri "$base/videos/$vid/playback-token" -Method POST
$streamHeaders = @{ Authorization = "Bearer $($playback.playbackToken)" }
$stream = Invoke-RestMethod -Uri "$base/videos/$vid/stream" -Method GET -Headers $streamHeaders

# Display result
Write-Host "`n=== FINAL RESULT ===" -ForegroundColor Cyan
Write-Host "manifestUrl: $($stream.manifestUrl)" -ForegroundColor White

if ($stream.manifestUrl -match "^https://pub-") {
    Write-Host "`n✓ SUCCESS: Always returns absolute URL" -ForegroundColor Green
    Write-Host "✓ Ready to commit and open PR" -ForegroundColor Green
} else {
    Write-Host "`n✗ FAIL: Not absolute URL" -ForegroundColor Red
}
