$baseUrl = "http://localhost:4000/api"

Write-Host "Testing analytics endpoint directly..." -ForegroundColor Cyan

# Get a video ID
$videos = Invoke-RestMethod -Uri "$baseUrl/videos?limit=1" -Method Get
$videoId = $videos[0].id
Write-Host "Video ID: $videoId" -ForegroundColor Yellow

# Test the endpoint with timeout
Write-Host "`nSending watch session request..." -ForegroundColor Yellow
try {
  $body = @{ videoId = $videoId } | ConvertTo-Json
  Write-Host "Body: $body" -ForegroundColor Gray
  
  $response = Invoke-RestMethod -Uri "$baseUrl/analytics/watch/start" `
    -Method Post `
    -Body $body `
    -ContentType "application/json" `
    -TimeoutSec 5
  
  Write-Host "[SUCCESS] Response:" -ForegroundColor Green
  $response | ConvertTo-Json
} catch {
  Write-Host "[ERROR] Failed:" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  if ($_.ErrorDetails) {
    Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
  }
}