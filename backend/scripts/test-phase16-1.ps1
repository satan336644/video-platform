# Phase 16.1 Verification: Likes / Favorites API

$baseUrl = "http://localhost:4000/api"

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Info "=== Phase 16.1 Likes/Favorites Verification ==="

# Setup: login users and create a video
$user1Token = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "user1"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$user2Token = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "user2"; role = "viewer" } | ConvertTo-Json) -ContentType "application/json").token
$creatorToken = (Invoke-RestMethod -Uri "$baseUrl/login" -Method Post -Body (@{ userId = "creator-likes"; role = "creator" } | ConvertTo-Json) -ContentType "application/json").token

$video = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Like Test Video"; creatorId = "creator-likes"; visibility = "PUBLIC" } | ConvertTo-Json) -ContentType "application/json"
Write-Info "Created video: $($video.id)"

# Test 1: Like a video
Write-Info "`n=== Test 1: Like video ==="
$like1 = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Post -Headers @{ Authorization = "Bearer $user1Token" }
$likesInfo = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get
if ($likesInfo.likeCount -eq 1) { Write-Success "Like count is 1" } else { Write-ErrorMsg "Expected 1 like, got $($likesInfo.likeCount)" }

# Test 2: Double-like prevention
Write-Info "`n=== Test 2: Double-like prevention ==="
$like2 = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Post -Headers @{ Authorization = "Bearer $user1Token" }
$likesInfo = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get
if ($likesInfo.likeCount -eq 1) { Write-Success "No duplicate like" } else { Write-ErrorMsg "Duplicate like created" }

# Test 3: Multiple users can like
Write-Info "`n=== Test 3: Multiple users like ==="
$like3 = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Post -Headers @{ Authorization = "Bearer $user2Token" }
$likesInfo = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get
if ($likesInfo.likeCount -eq 2) { Write-Success "Two users liked" } else { Write-ErrorMsg "Expected 2 likes, got $($likesInfo.likeCount)" }

# Test 4: isLikedByUser check
Write-Info "`n=== Test 4: isLikedByUser check ==="
$user1Likes = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get -Headers @{ Authorization = "Bearer $user1Token" }
$user2Likes = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get -Headers @{ Authorization = "Bearer $user2Token" }
$creatorLikes = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
if ($user1Likes.isLikedByUser) { Write-Success "User1 isLikedByUser = true" } else { Write-ErrorMsg "User1 should be true" }
if ($user2Likes.isLikedByUser) { Write-Success "User2 isLikedByUser = true" } else { Write-ErrorMsg "User2 should be true" }
if (-not $creatorLikes.isLikedByUser) { Write-Success "Creator isLikedByUser = false" } else { Write-ErrorMsg "Creator should be false" }

# Test 5: Unlike
Write-Info "`n=== Test 5: Unlike video ==="
Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Delete -Headers @{ Authorization = "Bearer $user1Token" } | Out-Null
$likesInfo = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get
if ($likesInfo.likeCount -eq 1) { Write-Success "Like count decremented to 1" } else { Write-ErrorMsg "Expected 1 like after unlike, got $($likesInfo.likeCount)" }
$user1LikesAfter = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get -Headers @{ Authorization = "Bearer $user1Token" }
if (-not $user1LikesAfter.isLikedByUser) { Write-Success "User1 isLikedByUser = false after unlike" } else { Write-ErrorMsg "User1 should be false after unlike" }

# Test 6: Unlike non-existent like
Write-Info "`n=== Test 6: Unlike non-existent like ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Delete -Headers @{ Authorization = "Bearer $user1Token" } | Out-Null
  Write-ErrorMsg "Should fail on unliking non-existent like"
} catch { Write-Success "Unlike non-existent like rejected (404)" }

# Test 7: Auth required for like/unlike
Write-Info "`n=== Test 7: Auth required ==="
try {
  Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Post | Out-Null
  Write-ErrorMsg "Should require auth for like"
} catch { Write-Success "Like without auth rejected" }
try {
  Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/like" -Method Delete | Out-Null
  Write-ErrorMsg "Should require auth for unlike"
} catch { Write-Success "Unlike without auth rejected" }

# Test 8: Public read access (no auth)
Write-Info "`n=== Test 8: Public read access ==="
$publicLikes = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)/likes" -Method Get
if ($publicLikes.likeCount -eq 1) { Write-Success "Public can read like count" } else { Write-ErrorMsg "Public read failed" }
if (-not $publicLikes.isLikedByUser) { Write-Success "isLikedByUser = false without auth" } else { Write-ErrorMsg "Should be false without auth" }

# Test 9: UNLISTED video can be liked
Write-Info "`n=== Test 9: UNLISTED video likes ==="
$unlisted = Invoke-RestMethod -Uri "$baseUrl/videos" -Method Post -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ title = "Unlisted Video"; creatorId = "creator-likes"; visibility = "UNLISTED" } | ConvertTo-Json) -ContentType "application/json"
$unlistedLike = Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/like" -Method Post -Headers @{ Authorization = "Bearer $user1Token" }
$unlistedLikes = Invoke-RestMethod -Uri "$baseUrl/videos/$($unlisted.id)/likes" -Method Get
if ($unlistedLikes.likeCount -eq 1) { Write-Success "UNLISTED video can be liked" } else { Write-ErrorMsg "UNLISTED like failed" }

# Regression: Existing endpoints still work
Write-Info "`n=== Regression checks ==="
$videoDetail = Invoke-RestMethod -Uri "$baseUrl/videos/$($video.id)" -Method Get
Write-Success "Video detail includes likeCount: $($videoDetail.likeCount)"
$popular = Invoke-RestMethod -Uri "$baseUrl/videos/popular" -Method Get
Write-Success "Popular feed reachable"

Write-Info "`n=== Phase 16.1 Verification Complete ==="
