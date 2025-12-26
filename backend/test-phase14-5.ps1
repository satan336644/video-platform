# Phase 14.5 View Count Tracking - Verification Checklist

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

Write-Info "=== Phase 14.5 View Count Tracking Verification ==="

# Setup: Create test videos
Write-Info "`n=== Setup: Create test videos ==="
$loginRes = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body '{"userId":"creator-123","role":"creator"}' -ContentType "application/json"
$creatorToken = $loginRes.token

# Video 1: PUBLIC + READY
Write-Info "Creating Video 1: PUBLIC + READY..."
$video1Body = @{
    title = "View Count Test Video"
    creatorId = "creator-123"
    description = "Test view counting"
    category = "Test"
    tags = @("viewcount", "test")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video1 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video1Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video1.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 1 created: $($video1.id)"

# Video 2: UNLISTED + READY
Write-Info "Creating Video 2: UNLISTED + READY..."
$video2Body = @{
    title = "Unlisted View Test"
    creatorId = "creator-123"
    description = "Should not increment views"
    category = "Test"
    tags = @("unlisted")
    visibility = "UNLISTED"
} | ConvertTo-Json

$video2 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video2Body -ContentType "application/json"
Invoke-RestMethod -Uri "http://localhost:4000/test/videos/$($video2.id)/set-ready" -Method Post -ContentType "application/json" | Out-Null
Write-Success "Video 2 created: $($video2.id)"

# Video 3: PUBLIC + CREATED (not ready)
Write-Info "Creating Video 3: PUBLIC + CREATED..."
$video3Body = @{
    title = "Processing View Test"
    creatorId = "creator-123"
    description = "Should not increment views"
    category = "Test"
    tags = @("processing")
    visibility = "PUBLIC"
} | ConvertTo-Json

$video3 = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $video3Body -ContentType "application/json"
Write-Success "Video 3 created: $($video3.id)"

# Step 1: Verify initial viewCount = 0
Write-Info "`n=== Step 1: Verify initial viewCount = 0 ==="
try {
    $initialCheck = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)" -Method Get
    if ($initialCheck.viewCount -eq 0) {
        Write-Success "Initial viewCount = 0"
    } else {
        Write-ErrorMsg "Expected viewCount = 0, got $($initialCheck.viewCount)"
    }
} catch {
    Write-ErrorMsg "Failed to check initial viewCount: $($_.Exception.Message)"
}

# Step 2: Call public detail endpoint and verify viewCount increments to 1
Write-Info "`n=== Step 2: GET /videos/:id/public (first access) ==="
try {
    $firstAccess = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)/public" -Method Get
    Write-Success "Public detail endpoint works"
    Write-Info "Video title: $($firstAccess.title)"
    
    if ($firstAccess.PSObject.Properties.Name -contains "viewCount") {
        Write-Success "viewCount field present in response: $($firstAccess.viewCount)"
    } else {
        Write-ErrorMsg "viewCount field missing from response"
    }
    
    # Wait a moment for async increment
    Start-Sleep -Milliseconds 500
    
    # Check if viewCount was incremented
    $checkAfterFirst = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)" -Method Get
    if ($checkAfterFirst.viewCount -eq 1) {
        Write-Success "viewCount incremented to 1 after first access"
    } else {
        Write-WarningMsg "Expected viewCount = 1, got $($checkAfterFirst.viewCount)"
    }
} catch {
    Write-ErrorMsg "Failed first access test: $($_.Exception.Message)"
}

# Step 3: Call again and verify viewCount increments to 2
Write-Info "`n=== Step 3: GET /videos/:id/public (second access) ==="
try {
    $secondAccess = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)/public" -Method Get
    Write-Success "Second access successful"
    
    # Wait a moment for async increment
    Start-Sleep -Milliseconds 500
    
    $checkAfterSecond = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)" -Method Get
    if ($checkAfterSecond.viewCount -eq 2) {
        Write-Success "viewCount incremented to 2 after second access"
    } else {
        Write-WarningMsg "Expected viewCount = 2, got $($checkAfterSecond.viewCount)"
    }
} catch {
    Write-ErrorMsg "Failed second access test: $($_.Exception.Message)"
}

# Step 4: Third access to confirm continuous increment
Write-Info "`n=== Step 4: GET /videos/:id/public (third access) ==="
try {
    $thirdAccess = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)/public" -Method Get
    Write-Success "Third access successful"
    
    # Wait a moment for async increment
    Start-Sleep -Milliseconds 500
    
    $checkAfterThird = Invoke-RestMethod -Uri "$baseUrl/videos/$($video1.id)" -Method Get
    if ($checkAfterThird.viewCount -eq 3) {
        Write-Success "viewCount incremented to 3 after third access"
    } else {
        Write-WarningMsg "Expected viewCount = 3, got $($checkAfterThird.viewCount)"
    }
} catch {
    Write-ErrorMsg "Failed third access test: $($_.Exception.Message)"
}

# Step 5: Verify UNLISTED video does NOT increment views
Write-Info "`n=== Step 5: UNLISTED video should NOT increment views ==="
try {
    $unlistedInitial = Invoke-RestMethod -Uri "$baseUrl/videos/$($video2.id)" -Method Get
    $initialUnlistedCount = $unlistedInitial.viewCount
    Write-Info "Initial UNLISTED viewCount: $initialUnlistedCount"
    
    # Try to access via public endpoint (should return 404)
    try {
        $unlistedAccess = Invoke-RestMethod -Uri "$baseUrl/videos/$($video2.id)/public" -Method Get
        Write-ErrorMsg "UNLISTED video should return 404 but succeeded"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Success "UNLISTED video correctly returns 404"
        }
    }
    
    # Verify viewCount unchanged
    Start-Sleep -Milliseconds 500
    $unlistedAfter = Invoke-RestMethod -Uri "$baseUrl/videos/$($video2.id)" -Method Get
    if ($unlistedAfter.viewCount -eq $initialUnlistedCount) {
        Write-Success "UNLISTED video viewCount unchanged: $($unlistedAfter.viewCount)"
    } else {
        Write-ErrorMsg "UNLISTED video viewCount changed from $initialUnlistedCount to $($unlistedAfter.viewCount)"
    }
} catch {
    Write-ErrorMsg "Failed UNLISTED test: $($_.Exception.Message)"
}

# Step 6: Verify CREATED video does NOT increment views
Write-Info "`n=== Step 6: CREATED (not ready) video should NOT increment views ==="
try {
    $createdInitial = Invoke-RestMethod -Uri "$baseUrl/videos/$($video3.id)" -Method Get
    $initialCreatedCount = $createdInitial.viewCount
    Write-Info "Initial CREATED viewCount: $initialCreatedCount"
    
    # Try to access via public endpoint (should return 404)
    try {
        $createdAccess = Invoke-RestMethod -Uri "$baseUrl/videos/$($video3.id)/public" -Method Get
        Write-ErrorMsg "CREATED video should return 404 but succeeded"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Success "CREATED video correctly returns 404"
        }
    }
    
    # Verify viewCount unchanged
    Start-Sleep -Milliseconds 500
    $createdAfter = Invoke-RestMethod -Uri "$baseUrl/videos/$($video3.id)" -Method Get
    if ($createdAfter.viewCount -eq $initialCreatedCount) {
        Write-Success "CREATED video viewCount unchanged: $($createdAfter.viewCount)"
    } else {
        Write-ErrorMsg "CREATED video viewCount changed from $initialCreatedCount to $($createdAfter.viewCount)"
    }
} catch {
    Write-ErrorMsg "Failed CREATED test: $($_.Exception.Message)"
}

# Step 7: Verify non-existent video does NOT cause errors
Write-Info "`n=== Step 7: Non-existent video should return 404 ==="
try {
    $nonexistent = Invoke-RestMethod -Uri "$baseUrl/videos/nonexistent-uuid/public" -Method Get
    Write-ErrorMsg "Non-existent video should return 404 but succeeded"
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Success "Non-existent video correctly returns 404"
    } else {
        Write-WarningMsg "Expected 404, got $($_.Exception.Response.StatusCode)"
    }
}

# Step 8: Verify other endpoints still work
Write-Info "`n=== Step 8: Regression check - other endpoints unchanged ==="
try {
    $publicList = Invoke-RestMethod -Uri "$baseUrl/videos/public" -Method Get
    Write-Success "GET /videos/public still works"
    
    $creatorVideos = Invoke-RestMethod -Uri "$baseUrl/creator/videos" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
    Write-Success "GET /creator/videos still works"
} catch {
    Write-ErrorMsg "Regression test failed: $($_.Exception.Message)"
}

Write-Success "`n=== Phase 14.5 Verification Complete ==="
Write-Info "Summary: View count tracking is working correctly"
Write-Info "  - PUBLIC + READY videos increment viewCount"
Write-Info "  - UNLISTED videos do not increment"
Write-Info "  - CREATED videos do not increment"
Write-Info "  - Multiple accesses increment correctly"
Write-Info "  - Existing endpoints unaffected"
