$baseUrl = "http://localhost:4000/api"

Write-Host "`n=== Video Creation Setup ===`n" -ForegroundColor Cyan

# Step 1: Login as creator
Write-Host "Step 1: Logging in as creator..." -ForegroundColor Yellow
try {
  $login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post `
    -Body '{"email":"creator1@example.com","password":"SecurePass123"}' `
    -ContentType "application/json"
  $token = $login.accessToken
  $creatorId = $login.user.id
  Write-Host "[OK] Logged in as $($login.user.username) (ID: $creatorId)" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Login failed: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Step 2: Create test videos with different categories and tags
Write-Host "`nStep 2: Creating test videos..." -ForegroundColor Yellow

$testVideos = @(
  @{
    title = "Amateur Content Tutorial"
    description = "Getting started guide for new creators"
    categories = @("AMATEUR", "INSTRUCTIONAL")
    tags = @("tutorial", "beginner", "guide", "tips", "howto")
  },
  @{
    title = "Professional Production"
    description = "High quality professional content showcase"
    categories = @("PROFESSIONAL", "POV")
    tags = @("professional", "hd", "quality", "premium", "showcase")
  },
  @{
    title = "Solo Performance"
    description = "Solo content collection"
    categories = @("SOLO", "AMATEUR")
    tags = @("solo", "performance", "intimate", "personal", "creative")
  },
  @{
    title = "Couples Content"
    description = "Couples content series"
    categories = @("COUPLE", "AMATEUR")
    tags = @("couple", "together", "intimate", "partners", "duo")
  },
  @{
    title = "Cosplay Collection"
    description = "Creative cosplay and roleplay content"
    categories = @("COSPLAY", "ROLEPLAY")
    tags = @("cosplay", "roleplay", "costume", "creative", "fantasy")
  },
  @{
    title = "Compilation Best Of"
    description = "Best moments compilation video"
    categories = @("COMPILATION")
    tags = @("compilation", "best-of", "highlights", "collection", "montage")
  }
)

$videoIds = @()

foreach ($video in $testVideos) {
  try {
    $payload = @{
      title = $video.title
      description = $video.description
      creatorId = $creatorId
      categories = $video.categories
      tags = $video.tags
      visibility = "PUBLIC"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post `
      -Headers @{ Authorization = "Bearer $token" } `
      -Body $payload -ContentType "application/json"
    
    $videoId = $response.id
    $videoIds += $videoId
    
    Write-Host "[OK] Created: '$($video.title)'" -ForegroundColor Green
    Write-Host "     ID: $videoId" -ForegroundColor Gray
    Write-Host "     Categories: $($video.categories -join ', ')" -ForegroundColor Gray
    Write-Host "     Tags: $($video.tags -join ', ')" -ForegroundColor Gray
  } catch {
    $errorDetails = $_.ErrorDetails.Message
    Write-Host "[FAIL] Failed to create '$($video.title)': $errorDetails" -ForegroundColor Red
  }
}

# Step 3: Verify videos were created
Write-Host "`nStep 3: Verifying videos..." -ForegroundColor Yellow
try {
  $videosList = Invoke-RestMethod -Uri "$baseUrl/videos?limit=20" -Method Get
  Write-Host "[OK] Total videos in system: $($videosList.videos.Count)" -ForegroundColor Green
  
  Write-Host "`nCreated videos:" -ForegroundColor Yellow
  foreach ($id in $videoIds) {
    $video = $videosList.videos | Where-Object { $_.id -eq $id }
    if ($video) {
      Write-Host "  - $($video.title)" -ForegroundColor Green
    }
  }
} catch {
  Write-Host "[FAIL] Verification failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Video Creation Complete ===`n" -ForegroundColor Cyan
Write-Host "You now have $($videoIds.Count) test videos ready for analytics testing!" -ForegroundColor Green
Write-Host "`nVideo IDs:" -ForegroundColor Yellow
foreach ($id in $videoIds) {
  Write-Host "  - $id" -ForegroundColor Gray
}