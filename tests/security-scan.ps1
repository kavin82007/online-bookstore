$html = Get-Content -Raw "index.html"
$docker = Get-Content -Raw "Dockerfile"
$issues = @()

if ($html -match '(?i)(password|api[_-]?key|secret|dckr_pat_|ghp_)\s*[:=]') { $issues += "Hard-coded secret or credential in index.html" }
if ($html -match '(?i)<script[^>]+src=["'']http://') { $issues += "Script loaded over insecure HTTP" }
if ($html -match '(?i)\beval\s*\(') { $issues += "Use of eval() detected" }
if ($html -match '(?i)document\.write\s*\(') { $issues += "Use of document.write() detected" }
if ($docker -match '(?im)^FROM\s+\S+:latest') { $issues += "Dockerfile uses an unpinned :latest base image" }
if ($docker -notmatch '(?im)^FROM\s+\S+:\S+') { $issues += "Dockerfile base image has no version tag" }

if ($issues.Count -gt 0) {
    $issues | ForEach-Object { Write-Host "SECURITY FAIL: $_" }
    exit 1
}
Write-Host "Security scan passed - no issues found"