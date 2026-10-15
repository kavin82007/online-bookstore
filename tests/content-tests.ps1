$html = Get-Content -Raw "index.html"
$script:fail = 0

function Check($name, $condition) {
    if ($condition) { Write-Host "PASS: $name" }
    else { Write-Host "FAIL: $name"; $script:fail++ }
}

$books = ([regex]::Matches($html, 'class="book"')).Count
Check "At least 6 books listed (found $books)" ($books -ge 6)
Check "Every book shows a price" (([regex]::Matches($html, 'class="price"')).Count -ge $books)
Check "Every book has an availability label" (([regex]::Matches($html, 'class="stock ')).Count -ge $books)
Check "Search by title/author box present" ($html -match 'id="search"')
Check "Category filter present" ($html -match 'id="category"')
Check "Shopping cart present" ($html -match 'id="cart-items"')
Check "Place order function present" ($html -match 'function placeOrder')
Check "Order tracking function present" ($html -match 'function trackOrder')
Check "Customer rating summary present" ($html -match 'id="rating-summary"')

if ($script:fail -gt 0) { Write-Host "$($script:fail) content test(s) FAILED"; exit 1 }
Write-Host "All content tests passed"