param (
    [Parameter(Mandatory = $true)]
    [string]$value
)

# Delete pubspec.lock in the ./jewel directory
$relativePath = ".\jewel\pubspec.lock"

if (Test-Path $relativePath) {
    Remove-Item $relativePath -Force
    Write-Host "File '$relativePath' deleted successfully."
} else {
    Write-Host "File '$relativePath' does not exist."
}

# Change directory to 'jewel'
Set-Location ".\jewel"
Write-Host "Changed directory to 'jewel'."

# Run 'flutter clean' and wait
Write-Host "Running 'flutter clean'..."
Start-Process "flutter" -ArgumentList "clean" -NoNewWindow -Wait

# Run 'flutter build <value>' and wait
Write-Host "Running 'flutter build $value'..."
Start-Process "flutter" -ArgumentList "build $value" -NoNewWindow -Wait
