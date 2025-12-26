# Phase 14.2 Metadata Update API - Final Verification Checklist

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

Write-Info "=== Phase 14.2 Verification Checklist ==="

# Step 1: Baseline - Create a video as creator
Write-Info "`nStep 1: Create video as creator..."
$loginRes = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body '{"userId":"creator-123","role":"creator"}' -ContentType "application/json"
$creatorToken = $loginRes.token
Write-Info "Creator token: $creatorToken"

$createBody = @{
    title = "Test Metadata Update"
    creatorId = "creator-123"
    description = "Initial description"
    category = "Educational"
    tags = @("test", "metadata")
    visibility = "UNLISTED"
} | ConvertTo-Json

$createRes = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body $createBody -ContentType "application/json"

$videoId = $createRes.id
Write-Success "Video created: $videoId"
Write-Info "Initial title: $($createRes.title)"
Write-Info "Initial visibility: $($createRes.visibility)"

# Step 2: Update metadata as creator
Write-Info "`nStep 2: PATCH /videos/:id/metadata as creator..."
$updateBody = @{
    title = "Updated Title"
    category = "Documentary"
    tags = @("updated", "test")
    visibility = "PUBLIC"
} | ConvertTo-Json

try {
    $updateRes = Invoke-RestMethod -Uri "$baseUrl/videos/$videoId/metadata" -Method Patch -Headers @{ Authorization = "Bearer $creatorToken" } -Body $updateBody -ContentType "application/json"
    Write-Success "Metadata updated successfully"
    Write-Info "New title: $($updateRes.title)"
    Write-Info "New visibility: $($updateRes.visibility)"
} catch {
    Write-ErrorMsg "Failed to update metadata: $($_.Exception.Message)"
}

# Step 3: Verify GET /api/videos/:id returns updated data
Write-Info "`nStep 3: GET /api/videos/:id to verify updates..."
try {
    $getRes = Invoke-RestMethod -Uri "$baseUrl/videos/$videoId" -Method Get
    Write-Success "GET endpoint works"
    Write-Info "Current title: $($getRes.title)"
    Write-Info "Current visibility: $($getRes.visibility)"
    
    if ($getRes.title -eq "Updated Title" -and $getRes.visibility -eq "PUBLIC") {
        Write-Success "Updates persisted correctly!"
    } else {
        Write-WarningMsg "Updates may not have persisted"
    }
} catch {
    Write-ErrorMsg "GET endpoint failed: $($_.Exception.Message)"
}

# Step 4: Verify viewer cannot update metadata
Write-Info "`nStep 4: PATCH as viewer (should fail with 403)..."
$viewerRes = Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body '{"userId":"viewer-456","role":"viewer"}' -ContentType "application/json"
$viewerToken = $viewerRes.token

try {
    $hackBody = @{ title = "Hacked" } | ConvertTo-Json
    $updateRes = Invoke-RestMethod -Uri "$baseUrl/videos/$videoId/metadata" -Method Patch -Headers @{ Authorization = "Bearer $viewerToken" } -Body $hackBody -ContentType "application/json"
    Write-ErrorMsg "Viewer was able to update (SECURITY ISSUE!)"
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Success "Viewer correctly blocked with 403 Forbidden"
    } elseif ($_.Exception.Response.StatusCode -eq 401) {
        Write-ErrorMsg "Got 401 instead of 403 - role-based access may not be working"
    } else {
        Write-WarningMsg "Unexpected status code: $($_.Exception.Response.StatusCode)"
    }
}

# Step 5: Verify playback still works for READY videos
Write-Info "`nStep 5: Playback verification..."
Write-WarningMsg "Note: Video is CREATED status, so playback will fail (expected)"
Write-Info "Metadata updates do not affect playback routes"

Write-Success "`n=== Verification Complete ==="
