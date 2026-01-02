$baseUrl = "http://localhost:4000/api"

Write-Host "`n=== Creating Phase 19 Test Data ===`n" -ForegroundColor Cyan

# Login as test creator
Write-Host "Logging in as test creator..." -ForegroundColor Yellow
try {
  $login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
    email = "testcreator@test.com"
    password = "TestPass123"
  } | ConvertTo-Json) -ContentType "application/json"
  $token = $login.accessToken
  $creatorId = $login.user.id
  Write-Host "[OK] Logged in as $($login.user.username)" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Login failed.  Make sure testcreator@test.com exists (from Phase 18)" -ForegroundColor Red
  Write-Host "Run: npx prisma db seed" -ForegroundColor Yellow
  exit 1
}

# Create test videos with categories and tags
$testVideos = @(
  @{
    title = "Amateur Foot Fetish Video"
    description = "A test video for amateur foot content"
    categories = @("AMATEUR", "FOOT_FETISH")
    tags = @("feet", "amateur", "solo", "hd")
  },
  @{
    title = "Transgender Couple Scene"
    description = "Professional transgender couple content"
    categories = @("TRANSGENDER", "COUPLE", "PROFESSIONAL")
    tags = @("trans", "couple", "professional", "hardcore")
  },
  @{
    title = "SM BDSM Solo Performance"
    description = "Solo BDSM performance video"
    categories = @("SM_BDSM", "SOLO")
    tags = @("bdsm", "solo", "bondage", "amateur")
  },
  @{
    title = "POV Cosplay Roleplay"
    description = "POV cosplay roleplay video"
    categories = @("POV", "COSPLAY", "ROLEPLAY")
    tags = @("pov", "cosplay", "roleplay", "anime")
  },
  @{
    title = "Vintage Amateur Compilation"
    description = "Vintage style amateur compilation"
    categories = @("VINTAGE", "AMATEUR", "COMPILATION")
    tags = @("vintage", "retro", "compilation", "classic")
  },
  @{
    title = "Group Instructional Video"
    description = "Instructional group performance"
    categories = @("GROUP", "INSTRUCTIONAL")
    tags = @("group", "tutorial", "instructional", "educational")
  }
)

Write-Host "`nCreating test videos..." -ForegroundColor Yellow

$createdVideos = @()

foreach ($videoData in $testVideos) {
  try {
    $body = @{
      title = $videoData.title
      description = $videoData.description
      creatorId = $creatorId
      categories = $videoData.categories
      tags = $videoData.tags
      visibility = "PUBLIC"
    } | ConvertTo-Json

    $video = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post `
      -Headers @{ Authorization = "Bearer $token" } `
      -Body $body `
      -ContentType "application/json"

    # Set video to READY status
    Invoke-RestMethod -Uri "$baseUrl/test/videos/$($video.id)/set-ready" -Method Post | Out-Null
    
    # Set view count
    $randomViews = Get-Random -Minimum 10 -Maximum 1000
    Invoke-RestMethod -Uri "$baseUrl/test/videos/$($video.id)/set-views" -Method Post `
      -Body (@{ viewCount = $randomViews } | ConvertTo-Json) `
      -ContentType "application/json" | Out-Null

    $createdVideos += $video
    Write-Host "  ✓ Created: $($video.title)" -ForegroundColor Green

  } catch {
    Write-Host "  ✗ Failed to create video: $($_.Exception.Message)" -ForegroundColor Red
  }
}

Write-Host "`n[OK] Created $($createdVideos.Count) test videos" -ForegroundColor Green
Write-Host "`n=== Test Data Creation Complete ===`n" -ForegroundColor Cyan
# Write-Host "Now run: powershell -ExecutionPolicy Bypass -File scripts/test-phase19.ps1" -ForegroundColor Yellow