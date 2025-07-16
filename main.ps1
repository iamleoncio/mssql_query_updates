Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'

function Get-RepoContents($Path = '') {
    $encodedPath = if ($Path) { '/' + [uri]::EscapeDataString($Path) } else { '' }
    $url = "https://api.github.com/repos/$Owner/$Repo/contents$encodedPath?ref=$Branch"
    Invoke-RestMethod -Uri $url -Headers @{ 'User-Agent' = 'PowerShell' }
}

function Download-Folder($Path, $TargetFolder) {
    $items = Get-RepoContents $Path
    foreach ($item in $items) {
        $target = Join-Path $TargetFolder $item.name
        if ($item.type -eq 'file') {
            Invoke-WebRequest -Uri $item.download_url -OutFile $target
        } elseif ($item.type -eq 'dir') {
            if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target | Out-Null }
            Download-Folder -Path $item.path -TargetFolder $target
        }
    }
}

# GUI Setup
$form = New-Object Windows.Forms.Form
$form.Text = "Repo Browser"
$form.Size = '500,400'
$form.StartPosition = 'CenterScreen'
$form.BackColor = '#1e1e1e'
$form.ForeColor = 'White'

$label = New-Object Windows.Forms.Label
$label.Text = 'Select a Folder to Download'
$label.AutoSize = $true
$label.Font = 'Segoe UI,14'
$label.Top = 20
$label.Left = 140
$form.Controls.Add($label)

$listBox = New-Object Windows.Forms.ListBox
$listBox.Size = '400,200'
$listBox.Location = '45,60'
$form.Controls.Add($listBox)

$btn = New-Object Windows.Forms.Button
$btn.Text = "Download Selected"
$btn.Size = '180,30'
$btn.Location = '160,280'
$form.Controls.Add($btn)

$btn.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a folder.")
        return
    }

    $folder = $listBox.SelectedItem
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Download-Folder -Path $folder -TargetFolder $dlg.SelectedPath
        [System.Windows.Forms.MessageBox]::Show("Downloaded: $folder", "Done")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error downloading folder: $_")
    }
})

try {
    $folders = Get-RepoContents | Where-Object { $_.type -eq 'dir' }
    $folders | ForEach-Object { $listBox.Items.Add($_.name) }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to load folders: $_")
}

[void]$form.ShowDialog()
