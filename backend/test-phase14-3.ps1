# Phase 14.3 Discovery APIs - Verification Checklist

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

Write-Info "=== Phase 14.3 Discovery APIs Verification ==="

# Setup: Create test videos with different states
Write-Info "`n=== Setup: Create test videos ==="
$loginRes = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body '{"userId":"creator-123","role":"creator"}' -ContentType "application/json"
$creatorToken = $loginRes.token

# Video 1: PUBLIC + READY + latex tag
Write-Info "Creating Video 1: PUBLIC + READY + latex tag..."
$video1Body = @{
    title = "LaTeX Tutorial"
    creatorId = "creator-123"
    description = "Learn latex formatting"
    category = "Educational"
    tags = @("latex", "tutorial")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video1 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video1Body -ContentType "application/json"
# Update to READY status
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video1.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 1 created: $($video1.id)"

# Video 2: PUBLIC + READY + cosplay category
Write-Info "Creating Video 2: PUBLIC + READY + cosplay category..."
$video2Body = @{
    title = "Cosplay Guide"
    creatorId = "creator-123"
    description = "Amazing cosplay content"
    category = "cosplay"
    tags = @("costume", "guide")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video2Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video2.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 2 created: $($video2.id)"

# Video 3: PUBLIC + CREATED (should NOT appear in public lists)
Write-Info "Creating Video 3: PUBLIC + CREATED (not ready)..."
$video3Body = @{
    title = "Processing Video"
    creatorId = "creator-123"
    description = "Still processing"
    category = "Educational"
    tags = @("test")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video3 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video3Body -ContentType "application/json"
Write-WarningMsg "Video 3 created (CREATED status): $($video3.id)"

# Video 4: UNLISTED + READY (should NOT appear in public lists)
Write-Info "Creating Video 4: UNLISTED + READY..."
$video4Body = @{
    title = "Private Tutorial"
    creatorId = "creator-123"
    description = "Unlisted content"
    category = "Educational"
    tags = @("latex")
    visibility = "UNLISTED"
} | ConvertTo-Json

$video4 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video4Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video4.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-WarningMsg "Video 4 created (UNLISTED): $($video4.id)"

# Test 1: GET /videos/public (should return only video1 and video2)
Write-Info "`n=== Test 1: GET /videos/public ==="
try {
    $publicVideos = Invoke-RestMethod -Uri "$baseUrl/videos/public" -Method Get
    Write-Success "Public videos endpoint works"
    Write-Info "Found $($publicVideos.Count) public videos"
    
    if ($publicVideos.Count -eq 2) {
        Write-Success "Correct count: 2 videos (only PUBLIC + READY)"
    } else {
        Write-ErrorMsg "Expected 2 videos, got $($publicVideos.Count)"
    }
    
    # Verify all are PUBLIC and READY
    $allPublicReady = $publicVideos | Where-Object { $_.visibility -eq "PUBLIC" -and $_.status -eq "READY" }
    if ($allPublicReady.Count -eq $publicVideos.Count) {
        Write-Success "All videos are PUBLIC + READY"
    } else {
        Write-ErrorMsg "Some videos are not PUBLIC + READY"
    }
    
    # Verify sorted by createdAt desc
    $sorted = $publicVideos[0].createdAt -gt $publicVideos[1].createdAt
    if ($sorted) {
        Write-Success "Videos sorted by createdAt desc"
    } else {
        Write-WarningMsg "Videos may not be sorted correctly"
    }
} catch {
    Write-ErrorMsg "Failed to get public videos: $($_.Exception.Message)"
}

# Test 2: GET /videos/public?tag=latex (should return only video1)
Write-Info "`n=== Test 2: GET /videos/public?tag=latex ==="
try {
    $latexVideos = Invoke-RestMethod -Uri "$baseUrl/videos/public?tag=latex" -Method Get
    Write-Success "Tag filter works"
    Write-Info "Found $($latexVideos.Count) videos with tag 'latex'"
    
    if ($latexVideos.Count -eq 1 -and $latexVideos[0].title -eq "LaTeX Tutorial") {
        Write-Success "Correct: Found only 'LaTeX Tutorial' (PUBLIC + READY + latex tag)"
    } else {
        Write-ErrorMsg "Expected 1 video (LaTeX Tutorial), got $($latexVideos.Count)"
    }
} catch {
    Write-ErrorMsg "Failed to filter by tag: $($_.Exception.Message)"
}

# Test 3: GET /videos/public?category=cosplay (should return only video2)
Write-Info "`n=== Test 3: GET /videos/public?category=cosplay ==="
try {
    $cosplayVideos = Invoke-RestMethod -Uri "$baseUrl/videos/public?category=cosplay" -Method Get
    Write-Success "Category filter works"
    Write-Info "Found $($cosplayVideos.Count) videos in category 'cosplay'"
    
    if ($cosplayVideos.Count -eq 1 -and $cosplayVideos[0].title -eq "Cosplay Guide") {
        Write-Success "Correct: Found only 'Cosplay Guide'"
    } else {
        Write-ErrorMsg "Expected 1 video (Cosplay Guide), got $($cosplayVideos.Count)"
    }
} catch {
    Write-ErrorMsg "Failed to filter by category: $($_.Exception.Message)"
}

# Test 4: GET /videos/search?q=latex (should search title, description, tags)
Write-Info "`n=== Test 4: GET /videos/search?q=latex ==="
try {
    $searchResults = Invoke-RestMethod -Uri "$baseUrl/videos/search?q=latex" -Method Get
    Write-Success "Search endpoint works"
    Write-Info "Found $($searchResults.Count) videos matching 'latex'"
    
    if ($searchResults.Count -ge 1) {
        Write-Success "Search found videos with 'latex' in title/description/tags"
        $searchResults | ForEach-Object { Write-Info "  - $($_.title)" }
    } else {
        Write-ErrorMsg "Expected at least 1 result, got $($searchResults.Count)"
    }
} catch {
    Write-ErrorMsg "Failed to search videos: $($_.Exception.Message)"
}

# Test 5: GET /videos/search?q=cosplay
Write-Info "`n=== Test 5: GET /videos/search?q=cosplay ==="
try {
    $searchResults = Invoke-RestMethod -Uri "$baseUrl/videos/search?q=cosplay" -Method Get
    Write-Success "Search for 'cosplay' works"
    Write-Info "Found $($searchResults.Count) videos matching 'cosplay'"
    
    if ($searchResults.Count -ge 1) {
        Write-Success "Search found videos with 'cosplay' in title/description"
        $searchResults | ForEach-Object { Write-Info "  - $($_.title)" }
    } else {
        Write-ErrorMsg "Expected at least 1 result, got $($searchResults.Count)"
    }
} catch {
    Write-ErrorMsg "Failed to search videos: $($_.Exception.Message)"
}

# Test 6: Verify existing endpoints still work
Write-Info "`n=== Test 6: Verify existing endpoints unaffected ==="
try {
    $allVideos = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Get
    Write-Success "GET /videos still works (returns all videos)"
    Write-Info "Total videos in system: $($allVideos.Count)"
} catch {
    Write-ErrorMsg "GET /videos failed: $($_.Exception.Message)"
}

Write-Success "`n=== Phase 14.3 Verification Complete ==="
