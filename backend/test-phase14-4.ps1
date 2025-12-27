# Phase 14.4 Creator Dashboard & Public Detail APIs - Verification Checklist

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

Write-Info "=== Phase 14.4 Creator Dashboard & Public Detail APIs Verification ==="

# Setup: Create test videos
Write-Info "`n=== Setup: Create test videos ==="
$loginRes = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body '{"userId":"creator-123","role":"creator"}' -ContentType "application/json"
$creatorToken = $loginRes.token

# Video 1: PUBLIC + READY
Write-Info "Creating Video 1: PUBLIC + READY..."
$video1Body = @{
    title = "Public Video"
    creatorId = "creator-123"
    description = "This is public"
    category = "Educational"
    tags = @("public", "ready")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video1 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video1Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video1.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 1 created: $($video1.id)"

# Video 2: UNLISTED + READY
Write-Info "Creating Video 2: UNLISTED + READY..."
$video2Body = @{
    title = "Unlisted Video"
    creatorId = "creator-123"
    description = "This is unlisted"
    category = "Personal"
    tags = @("unlisted")
    visibility = "UNLISTED"
} | ConvertTo-Json

$video2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video2Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video2.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 2 created: $($video2.id)"

# Video 3: PRIVATE + CREATED
Write-Info "Creating Video 3: PRIVATE + CREATED..."
$video3Body = @{
    title = "Processing Video"
    creatorId = "creator-123"
    description = "Still processing"
    category = "Personal"
    tags = @("private")
    visibility = "PRIVATE"
} | ConvertTo-Json

$video3 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video3Body -ContentType "application/json"
Write-Success "Video 3 created: $($video3.id)"

# Test 1: GET /creator/videos (requires auth)
Write-Info "`n=== Test 1: GET /creator/videos (creator auth required) ==="
try {
    $creatorVideos = Invoke-RestMethod -Uri "$baseUrl/creator/videos" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
    Write-Success "Creator videos endpoint works"
    Write-Info "Found $($creatorVideos.videos.Count) videos for creator"
    
    if ($creatorVideos.pagination) {
        Write-Success "Pagination info present"
        Write-Info "  Total: $($creatorVideos.pagination.total), Pages: $($creatorVideos.pagination.pages)"
    }
} catch {
    Write-ErrorMsg "Failed to get creator videos: $($_.Exception.Message)"
}

# Test 2: GET /creator/videos without auth (should fail)
Write-Info "`n=== Test 2: GET /creator/videos without auth (should fail) ==="
try {
    $result = Invoke-RestMethod -Uri "$baseUrl/creator/videos" -Method Get
    Write-ErrorMsg "Should have required auth but succeeded"
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Success "Correctly requires authentication (401)"
    } else {
        Write-WarningMsg "Got status $($_.Exception.Response.StatusCode) instead of 401"
    }
}

# Test 3: GET /creator/videos?status=READY
Write-Info "`n=== Test 3: GET /creator/videos?status=READY (filter by status) ==="
try {
    $readyVideos = Invoke-RestMethod -Uri "$baseUrl/creator/videos?status=READY" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
    Write-Success "Status filter works"
    Write-Info "Found $($readyVideos.videos.Count) READY videos"
    
    if ($readyVideos.videos.Count -eq 2) {
        Write-Success "Correct: 2 READY videos (video1 and video2)"
    } else {
        Write-WarningMsg "Expected 2 READY videos, got $($readyVideos.videos.Count)"
    }
} catch {
    Write-ErrorMsg "Failed to filter by status: $($_.Exception.Message)"
}

# Test 4: GET /creator/videos?visibility=PUBLIC
Write-Info "`n=== Test 4: GET /creator/videos?visibility=PUBLIC (filter by visibility) ==="
try {
    $publicVideos = Invoke-RestMethod -Uri "$baseUrl/creator/videos?visibility=PUBLIC" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
    Write-Success "Visibility filter works"
    Write-Info "Found $($publicVideos.videos.Count) PUBLIC videos"
    
    if ($publicVideos.videos.Count -ge 1) {
        Write-Success "Found PUBLIC videos for creator"
    }
} catch {
    Write-ErrorMsg "Failed to filter by visibility: $($_.Exception.Message)"
}

# Test 5: GET /creator/videos?page=1&limit=10 (pagination)
Write-Info "`n=== Test 5: GET /creator/videos?page=1&limit=10 (pagination) ==="
try {
    $paginated = Invoke-RestMethod -Uri "$baseUrl/creator/videos?page=1&limit=10" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
    Write-Success "Pagination works"
    Write-Info "Page 1, Limit 10: Got $($paginated.videos.Count) videos"
    Write-Info "Total pages: $($paginated.pagination.pages)"
} catch {
    Write-ErrorMsg "Failed to paginate: $($_.Exception.Message)"
}

# Test 6: GET /videos/:id/public (public, no auth required)
Write-Info "`n=== Test 6: GET /videos/:id/public for PUBLIC + READY (should succeed) ==="
try {
    $publicDetail = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)/public" -Method Get
    Write-Success "Public video detail endpoint works"
    Write-Info "Video title: $($publicDetail.title)"
    Write-Info "Video status: $($publicDetail.status)"
    Write-Info "Video visibility: $($publicDetail.visibility)"
    
    if ($publicDetail.creator) {
        Write-Success "Creator info included: $($publicDetail.creator.id)"
    }
    
    if ($publicDetail.playback) {
        Write-Success "Playback info included"
        Write-Info "Manifest URL: $($publicDetail.playback.manifestUrl)"
    }
} catch {
    Write-ErrorMsg "Failed to get public video detail: $($_.Exception.Message)"
}

# Test 7: GET /videos/:id/public for UNLISTED (should fail with 404)
Write-Info "`n=== Test 7: GET /videos/:id/public for UNLISTED (should fail with 404) ==="
try {
    $result = Invoke-RestMethod -Uri "$baseUrl/videos/$($video2.id)/public" -Method Get
    Write-ErrorMsg "Should have returned 404 for UNLISTED video but succeeded"
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Success "Correctly returns 404 for UNLISTED video"
    } else {
        Write-WarningMsg "Got status $($_.Exception.Response.StatusCode) instead of 404"
    }
}

# Test 8: GET /videos/:id/public for CREATED (should fail with 404)
Write-Info "`n=== Test 8: GET /videos/:id/public for CREATED (should fail with 404) ==="
try {
    $result = Invoke-RestMethod -Uri "$baseUrl/videos/$($video3.id)/public" -Method Get
    Write-ErrorMsg "Should have returned 404 for CREATED video but succeeded"
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Success "Correctly returns 404 for CREATED video"
    } else {
        Write-WarningMsg "Got status $($_.Exception.Response.StatusCode) instead of 404"
    }
}

# Test 9: GET /videos/:id/public for non-existent video (should fail with 404)
Write-Info "`n=== Test 9: GET /videos/:id/public for non-existent video (should fail with 404) ==="
try {
    $result = Invoke-RestMethod -Uri "$baseUrl/videos/nonexistent-id/public" -Method Get
    Write-ErrorMsg "Should have returned 404 for non-existent video but succeeded"
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Success "Correctly returns 404 for non-existent video"
    } else {
        Write-WarningMsg "Got status $($_.Exception.Response.StatusCode) instead of 404"
    }
}

Write-Success "`n=== Phase 14.4 Verification Complete ==="
 