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

function Get-Folder ($Path, $Target) {
    $items = Get-GitHubContent $Path
    foreach ($i in $items) {
        $dest = Join-Path $Target $i.name
        if ($i.type -eq 'file') {
            Invoke-WebRequest $i.download_url -OutFile $dest -Headers $Headers
        } elseif ($i.type -eq 'dir') {
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
            Get-Folder -Path $i.path -Target $dest
        }
    }
}

<<<<<<< HEAD
<# GUI ──────────────────────────────────────────── #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "$Repo Browser"
=======
# GUI Setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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

# Download button
$btn = New-Object Windows.Forms.Button
$btn.Text       = 'Download Selected Folder'
$btn.Size       = '200,30'
$btn.Location   = '150,300'
$btn.BackColor  = '#3a3d41'
$btn.ForeColor  = 'White'
$btn.Visible    = $false
$form.Controls.Add($btn)

$btn.Add_Click({
    if (-not $list.SelectedItem) {
        [Windows.Forms.MessageBox]::Show('Select a folder first.')
        return
    }
    $folder = $list.SelectedItem
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Get-Folder -Path $folder -Target $dlg.SelectedPath
        [Windows.Forms.MessageBox]::Show("$folder downloaded to:`n$($dlg.SelectedPath)",'Success')
    } catch {
        [Windows.Forms.MessageBox]::Show("Download failed:`n$_",'Error')
    }
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
