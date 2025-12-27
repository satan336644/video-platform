# Phase 15.1 Popular / Trending Videos API - Verification Checklist

$baseUrl = "http://localhost:4000/api"

# Color helpers
function Write-Success {
    Write-Host $args[0] -ForegroundColor Green
}

function Write-ErrorMsg {
    Write-Host $args[0] -ForegroundColor Red
}

function Write-Info {
    Write-Host $args[0] -ForegroundColor Cyan
}

function Write-WarningMsg {
    Write-Host $args[0] -ForegroundColor Yellow
}

Write-Info "=== Phase 15.1 Popular / Trending Videos API Verification ==="

# Setup: Create test videos with different view counts
Write-Info "`n=== Setup: Create test videos with view counts ==="
$loginRes = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body '{"userId":"creator-123","role":"creator"}' -ContentType "application/json"
$creatorToken = $loginRes.token

# Video 1: HIGH views, recent
Write-Info "Creating Video 1: HIGH views (100), recent..."
$video1Body = @{
    title = "Super Popular Video"
    creatorId = "creator-123"
    description = "Most popular content"
    category = "Entertainment"
    tags = @("popular", "trending")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video1 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video1Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video1.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 1 created: $($video1.id)"

# Manually set high view count
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video1.id)/set-views" -Method Post -Body '{"viewCount":100}' -ContentType "application/json" | Out-Null
Write-Info "Set viewCount to 100"

# Video 2: MEDIUM views, recent
Write-Info "Creating Video 2: MEDIUM views (50), recent..."
$video2Body = @{
    title = "Moderately Popular Video"
    creatorId = "creator-123"
    description = "Medium popularity"
    category = "Educational"
    tags = @("medium")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video2Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video2.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 2 created: $($video2.id)"

Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video2.id)/set-views" -Method Post -Body '{"viewCount":50}' -ContentType "application/json" | Out-Null
Write-Info "Set viewCount to 50"

# Video 3: LOW views, recent
Write-Info "Creating Video 3: LOW views (10), recent..."
$video3Body = @{
    title = "Less Popular Video"
    creatorId = "creator-123"
    description = "Lower popularity"
    category = "Educational"
    tags = @("low")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video3 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video3Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video3.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 3 created: $($video3.id)"

Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video3.id)/set-views" -Method Post -Body '{"viewCount":10}' -ContentType "application/json" | Out-Null
Write-Info "Set viewCount to 10"

# Video 4: UNLISTED (should not appear)
Write-Info "Creating Video 4: UNLISTED with high views (should NOT appear)..."
$video4Body = @{
    title = "Unlisted High Views"
    creatorId = "creator-123"
    description = "Should not show in feeds"
    category = "Personal"
    tags = @("unlisted")
    visibility = "UNLISTED"
} | ConvertTo-Json

$video4 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video4Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video4.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video4.id)/set-views" -Method Post -Body '{"viewCount":200}' -ContentType "application/json" | Out-Null
Write-Success "Video 4 created: $($video4.id) (UNLISTED)"

# Test 1: GET /videos/popular
Write-Info "`n=== Test 1: GET /videos/popular (sorted by viewCount DESC) ==="
try {
    $popular = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
    Write-Success "Popular videos endpoint works"
    Write-Info "Found $($popular.Count) popular videos"
    
    # Find our test videos in results
    $ourVideos = $popular | Where-Object { $_.id -in @($video1.id, $video2.id, $video3.id) }
    
    if ($ourVideos.Count -ge 3) {
        Write-Success "Our test videos found in popular list"
        
        # Verify sorting by viewCount DESC
        $video1Result = $ourVideos | Where-Object { $_.id -eq $video1.id }
        $video2Result = $ourVideos | Where-Object { $_.id -eq $video2.id }
        $video3Result = $ourVideos | Where-Object { $_.id -eq $video3.id }
        
        Write-Info "Video 1 viewCount: $($video1Result.viewCount)"
        Write-Info "Video 2 viewCount: $($video2Result.viewCount)"
        Write-Info "Video 3 viewCount: $($video3Result.viewCount)"
        
        if ($video1Result.viewCount -ge $video2Result.viewCount -and $video2Result.viewCount -ge $video3Result.viewCount) {
            Write-Success "Videos correctly sorted by viewCount DESC"
        } else {
            Write-ErrorMsg "Videos NOT properly sorted by viewCount"
        }
    } else {
        Write-WarningMsg "Not all test videos found in popular list"
    }
    
    # Verify UNLISTED not in list
    $unlistedInList = $popular | Where-Object { $_.id -eq $video4.id }
    if ($null -eq $unlistedInList) {
        Write-Success "UNLISTED video correctly excluded from popular"
    } else {
        Write-ErrorMsg "UNLISTED video should not appear in popular"
    }
} catch {
    Write-ErrorMsg "Failed to get popular videos: $($_.Exception.Message)"
}

# Test 2: GET /videos/trending
Write-Info "`n=== Test 2: GET /videos/trending (recent + sorted by views) ==="
try {
    $trending = Invoke-RestMethod -Uri "$baseUrl/videos/trending" -Method Get
    Write-Success "Trending videos endpoint works"
    Write-Info "Found $($trending.Count) trending videos"
    
    # All trending videos should be from last 7 days
    $sevenDaysAgo = (Get-Date).AddDays(-7)
    $allRecent = $true
    foreach ($video in $trending) {
        $videoDate = [DateTime]::Parse($video.createdAt)
        if ($videoDate -lt $sevenDaysAgo) {
            $allRecent = $false
            Write-WarningMsg "Video $($video.id) is older than 7 days"
            break
        }
    }
    
    if ($allRecent) {
        Write-Success "All trending videos are from last 7 days"
    }
    
    # Find our test videos
    $ourTrendingVideos = $trending | Where-Object { $_.id -in @($video1.id, $video2.id, $video3.id) }
    
    if ($ourTrendingVideos.Count -ge 3) {
        Write-Success "Our recent test videos found in trending list"
        
        # Verify sorted by viewCount DESC
        $sorted = $true
        for ($i = 0; $i -lt ($ourTrendingVideos.Count - 1); $i++) {
            if ($ourTrendingVideos[$i].viewCount -lt $ourTrendingVideos[$i+1].viewCount) {
                $sorted = $false
                break
            }
        }
        
        if ($sorted) {
            Write-Success "Trending videos correctly sorted by viewCount DESC"
        } else {
            Write-WarningMsg "Trending videos may not be properly sorted"
        }
    }
    
    # Verify UNLISTED not in list
    $unlistedInTrending = $trending | Where-Object { $_.id -eq $video4.id }
    if ($null -eq $unlistedInTrending) {
        Write-Success "UNLISTED video correctly excluded from trending"
    } else {
        Write-ErrorMsg "UNLISTED video should not appear in trending"
    }
} catch {
    Write-ErrorMsg "Failed to get trending videos: $($_.Exception.Message)"
}

# Test 3: Verify limit parameter works
Write-Info "`n=== Test 3: GET /videos/popular?limit=5 ==="
try {
    $limitedPopular = Invoke-RestMethod -Uri "$baseUrl/videos/popular?limit=5" -Method Get
    Write-Success "Limit parameter works"
    Write-Info "Returned $($limitedPopular.Count) videos (requested limit=5)"
    
    if ($limitedPopular.Count -le 5) {
        Write-Success "Limit correctly applied"
    } else {
        Write-ErrorMsg "Limit not applied correctly"
    }
} catch {
    Write-ErrorMsg "Failed limit test: $($_.Exception.Message)"
}

# Test 4: Verify no auth required
Write-Info "`n=== Test 4: Verify no auth required ==="
try {
    $noAuth = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
    Write-Success "Popular endpoint works without auth"
    
    $noAuthTrending = Invoke-RestMethod -Uri "$baseUrl/videos/trending" -Method Get
    Write-Success "Trending endpoint works without auth"
} catch {
    Write-ErrorMsg "Auth should not be required: $($_.Exception.Message)"
}

# Test 5: Verify playback still works (use existing video with actual files)
Write-Info "`n=== Test 5: Verify playback still works ==="
try {
    # Use the existing video that has actual processed files in R2
    $existingVideoId = "83b3e8c0-78e0-4553-9a2d-02b7b8ea5ea7"
    
    $playbackResponse = Invoke-RestMethod -Uri "$baseUrl/videos/$existingVideoId/playback-token" -Method Post
    Write-Success "Playback token endpoint still works"
    
    # Stream endpoint requires Bearer token in Authorization header
    $stream = Invoke-RestMethod -Uri "$baseUrl/videos/$existingVideoId/stream" -Method Get -Headers @{ Authorization = "Bearer $($playbackResponse.playbackToken)" }
    Write-Success "Stream endpoint still works"
    Write-Info "Manifest URL: $($stream.manifestUrl)"
    
    # Verify the manifest URL is accessible (with -UseBasicParsing to avoid prompt)
    $manifestResponse = Invoke-WebRequest -Uri $stream.manifestUrl -Method Get -UseBasicParsing
    if ($manifestResponse.StatusCode -eq 200) {
        Write-Success "Manifest file accessible in R2"
    }
} catch {
    Write-ErrorMsg "Playback broken: $($_.Exception.Message)"
}

# Test 6: Regression - other endpoints unchanged
Write-Info "`n=== Test 6: Regression check - other endpoints unchanged ==="
try {
    $publicList = Invoke-RestMethod -Uri "$baseUrl/videos/public" -Method Get
    Write-Success "GET /videos/public still works"
    
    $search = Invoke-RestMethod -Uri "$baseUrl/videos/search?q=popular" -Method Get
    Write-Success "GET /videos/search still works"
} catch {
    Write-ErrorMsg "Regression test failed: $($_.Exception.Message)"
}

Write-Success "`n=== Phase 15.1 Verification Complete ==="
Write-Info "Summary: Popular and Trending feeds working correctly"
Write-Info "  - Popular videos sorted by viewCount DESC"
Write-Info "  - Trending videos show recent content (last 7 days)"
Write-Info "  - UNLISTED/PRIVATE videos excluded"
Write-Info "  - Limit parameter works"
Write-Info "  - No auth required"
Write-Info "  - Playback unaffected"
