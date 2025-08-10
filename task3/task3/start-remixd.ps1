Write-Host "Starting remixd in background..." -ForegroundColor Green
Start-Job -ScriptBlock {
    Set-Location "C:\Users\15961\init_order\solidity_task\task3\task3"
    npx remixd
}

Write-Host "remixd is running in background. Check status with: Get-Job" -ForegroundColor Yellow
Write-Host "To stop remixd, run: Stop-Job -Name 'Job1' && Remove-Job -Name 'Job1'" -ForegroundColor Yellow
