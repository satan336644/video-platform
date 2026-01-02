$baseUrl = "http://localhost:4000/api"
Write-Host "`n=== Phase 19: Content Discovery Tests ===`n" -ForegroundColor Cyan

# Test 1: Get all categories
Write-Host "Test 1: Get all categories" -ForegroundColor Yellow
try {
  $categories = Invoke-RestMethod -Uri "$baseUrl/categories" -Method Get
  Write-Host "[OK] Got $($categories.categories.Count) categories" -ForegroundColor Green
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 2: Browse by category
Write-Host "`nTest 2: Browse amateur category" -ForegroundColor Yellow
try {
  $videos = Invoke-RestMethod -Uri "$baseUrl/categories/amateur/videos?page=1&limit=10" -Method Get
  Write-Host "[OK] Got $($videos.videos.Count) amateur videos (total: $($videos.pagination.total))" -ForegroundColor Green
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 3: Tag autocomplete
Write-Host "`nTest 3: Tag autocomplete (query: 'ama')" -ForegroundColor Yellow
try {
  $tags = Invoke-RestMethod -Uri "$baseUrl/tags/autocomplete?q=ama&limit=5" -Method Get
  Write-Host "[OK] Got $($tags.tags.Count) matching tags" -ForegroundColor Green
  $tags.tags | ForEach-Object { Write-Host "  - $($_.name) ($($_.useCount) uses)" -ForegroundColor Gray }
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 4: Popular tags
Write-Host "`nTest 4: Get popular tags" -ForegroundColor Yellow
try {
  $popular = Invoke-RestMethod -Uri "$baseUrl/tags/popular?limit=5" -Method Get
  Write-Host "[OK] Got $($popular.tags.Count) popular tags" -ForegroundColor Green
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 5: Search with filters
Write-Host "`nTest 5: Search videos (sort by views)" -ForegroundColor Yellow
try {
  $searchResults = Invoke-RestMethod -Uri "$baseUrl/search?sort=views&page=1&limit=5" -Method Get
  Write-Host "[OK] Found $($searchResults.pagination.total) total videos" -ForegroundColor Green
  if ($searchResults.videos.Count -gt 0) {
    Write-Host "  Top result: '$($searchResults.videos[0].title)' ($($searchResults.videos[0].viewCount) views)" -ForegroundColor Gray
  }
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 6: Search by category
Write-Host "`nTest 6: Search with category filter" -ForegroundColor Yellow
try {
  $catSearch = Invoke-RestMethod -Uri "$baseUrl/search?categories=amateur&page=1&limit=5" -Method Get
  Write-Host "[OK] Found $($catSearch.pagination.total) amateur videos" -ForegroundColor Green
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 7: Search by text
Write-Host "`nTest 7: Search by text query" -ForegroundColor Yellow
try {
  $textSearch = Invoke-RestMethod -Uri "$baseUrl/search?q=test&page=1&limit=5" -Method Get
  Write-Host "[OK] Found $($textSearch.pagination.total) videos matching 'test'" -ForegroundColor Green
} catch { Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red }

# Test 8: Invalid category
Write-Host "`nTest 8: Invalid category (expect 400)" -ForegroundColor Yellow
try {
  Invoke-RestMethod -Uri "$baseUrl/categories/invalid-category/videos" -Method Get -ErrorAction Stop
  Write-Host "[FAIL] Should have returned 400" -ForegroundColor Red
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 400) {
    Write-Host "[OK] Correctly rejected invalid category (400)" -ForegroundColor Green
  } else {
    Write-Host "[WARN] Expected 400, got $code" -ForegroundColor Yellow
  }
}

Write-Host "`n=== All Phase 19 Tests Completed ===`n" -ForegroundColor Cyan