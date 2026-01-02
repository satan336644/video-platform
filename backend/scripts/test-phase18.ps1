$baseUrl = "http://localhost:4000/api"
Write-Host "`n=== Phase 18: User Authentication System Tests ===`n" -ForegroundColor Cyan

# Test 1: Register creator
Write-Host "Test 1: Register creator account" -ForegroundColor Yellow
try {
  $creator = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body (@{ email = "newcreator$(Get-Random)@test.com"; username = "newcreator$(Get-Random)"; password = "TestPass123"; role = "CREATOR" } | ConvertTo-Json) -ContentType "application/json"
  Write-Host "[OK] Creator registered: $($creator.username)" -ForegroundColor Green
} catch { Write-Host "[FAIL] Registration failed: $($_.Exception.Message)" -ForegroundColor Red }

# Test 2: Register viewer
Write-Host "`nTest 2: Register viewer account" -ForegroundColor Yellow
try {
  $viewer = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body (@{ email = "newviewer$(Get-Random)@test.com"; username = "newviewer$(Get-Random)"; password = "ViewerPass456"; role = "VIEWER" } | ConvertTo-Json) -ContentType "application/json"
  Write-Host "[OK] Viewer registered: $($viewer.username)" -ForegroundColor Green
} catch { Write-Host "[FAIL] Registration failed: $($_.Exception.Message)" -ForegroundColor Red }

# Test 3: Duplicate email (should fail)
Write-Host "`nTest 3: Duplicate email registration (expect 409)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body (@{ email = "testcreator@test.com"; username = "different_user"; password = "Pass123456" } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
  Write-Host "[FAIL] Should have failed" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 409) { Write-Host "[OK] Correctly rejected duplicate email (409)" -ForegroundColor Green }
  else { Write-Host "[FAIL] Wrong error code: $code" -ForegroundColor Red }
}

# Test 4: Weak password (should fail)
Write-Host "`nTest 4: Weak password (expect 400)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body (@{ email = "weak@test.com"; username = "weakpass"; password = "weak" } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
  Write-Host "[FAIL] Should have failed" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 400) { Write-Host "[OK] Correctly rejected weak password (400)" -ForegroundColor Green }
  else { Write-Host "[FAIL] Wrong error code: $code" -ForegroundColor Red }
}

# Test 5: Login with creator
Write-Host "`nTest 5: Login creator" -ForegroundColor Yellow
try {
  $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{ email = "testcreator@test.com"; password = "TestPass123" } | ConvertTo-Json) -ContentType "application/json"
  $creatorToken = $loginResponse.accessToken
  $creatorRefresh = $loginResponse.refreshToken
  Write-Host "[OK] Creator logged in, got tokens" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Login failed: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Test 6: Wrong password (should fail)
Write-Host "`nTest 6: Login with wrong password (expect 401)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{ email = "testcreator@test.com"; password = "WrongPassword" } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
  Write-Host "[FAIL] Should have failed" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 401) { Write-Host "[OK] Correctly rejected wrong password (401)" -ForegroundColor Green }
  else { Write-Host "[FAIL] Wrong error code: $code" -ForegroundColor Red }
}

# Test 7: Get /me with token
Write-Host "`nTest 7: Get /users/me (auth required)" -ForegroundColor Yellow
try {
  $me = Invoke-RestMethod -Uri "$baseUrl/users/me" -Method Get -Headers @{ Authorization = "Bearer $creatorToken" }
  Write-Host "[OK] Got user data: $($me.username), role: $($me.role)" -ForegroundColor Green
} catch { Write-Host "[FAIL] Failed to get user data: $($_.Exception.Message)" -ForegroundColor Red }

# Test 8: Update profile
Write-Host "`nTest 8: Update profile" -ForegroundColor Yellow
try {
  $updated = Invoke-RestMethod -Uri "$baseUrl/users/me" -Method Patch -Headers @{ Authorization = "Bearer $creatorToken" } -Body (@{ displayName = "Test Creator 99"; bio = "Professional test creator"; socialLinks = @{ twitter = "testcreator99" } } | ConvertTo-Json) -ContentType "application/json"
  Write-Host "[OK] Profile updated: $($updated.profile.displayName)" -ForegroundColor Green
} catch { Write-Host "[FAIL] Profile update failed: $($_.Exception.Message)" -ForegroundColor Red }

# Test 9: Get public profile
Write-Host "`nTest 9: Get public profile (no auth)" -ForegroundColor Yellow
try {
  $publicProfile = Invoke-RestMethod -Uri "$baseUrl/users/testcreator99" -Method Get
  Write-Host "[OK] Got public profile: $($publicProfile.profile.displayName)" -ForegroundColor Green
} catch { Write-Host "[FAIL] Failed to get public profile: $($_.Exception.Message)" -ForegroundColor Red }

# Test 10: Refresh token
Write-Host "`nTest 10: Refresh access token" -ForegroundColor Yellow
try {
  $refreshed = Invoke-RestMethod -Uri "$baseUrl/auth/refresh" -Method Post -Body (@{ refreshToken = $creatorRefresh } | ConvertTo-Json) -ContentType "application/json"
  Write-Host "[OK] Got new access token" -ForegroundColor Green
} catch {
  Write-Host "[FAIL] Token refresh failed: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Test 11: Logout
Write-Host "`nTest 11: Logout (invalidate refresh token)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/auth/logout" -Method Post -Body (@{ refreshToken = $refreshed.refreshToken } | ConvertTo-Json) -ContentType "application/json"
  Write-Host "[OK] Logged out successfully" -ForegroundColor Green
} catch { Write-Host "[FAIL] Logout failed: $($_.Exception.Message)" -ForegroundColor Red }

# Test 12: Use invalidated refresh token (should fail)
Write-Host "`nTest 12: Use invalidated refresh token (expect 401)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/auth/refresh" -Method Post -Body (@{ refreshToken = $refreshed.refreshToken } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
  Write-Host "[FAIL] Should have failed" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 401) { Write-Host "[OK] Correctly rejected invalidated token (401)" -ForegroundColor Green }
  else { Write-Host "[FAIL] Wrong error code: $code" -ForegroundColor Red }
}

Write-Host "`n=== All Phase 18 Tests Completed ===`n" -ForegroundColor Cyan