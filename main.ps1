function Show-Menu {
    Clear-Host
    Write-Host "==== My PowerShell App ===="
    Write-Host "1. Clone Repo"
    Write-Host "2. Show System Info"
    Write-Host "0. Exit"
    $choice = Read-Host "Select an option"
    switch ($choice) {
        1 { git clone https://github.com/yourname/ps-tools.git $env:TEMP\ps-tools }
        2 { Get-ComputerInfo | Out-Host }
        0 { exit }
        default { Write-Host "Invalid option"; Pause }
    }
}

while ($true) { Show-Menu }
