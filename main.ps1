<<<<<<< HEAD
<# CONFIG ──────────────────────────────────────── #>
=======
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

>>>>>>> 219692d4d8365ce716e613de71f39d4a231e0503
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'

<<<<<<< HEAD
$Headers = @{ 'User-Agent' = 'PowerShell-GUI-App' }  # ✅ NO AUTHORIZATION HEADER

function Encode-Path ($Path) {
    ($Path -split '/') | ForEach-Object { [uri]::EscapeDataString($_) } -join '/'
=======
function Get-RepoContents($Path = '') {
    $encodedPath = if ($Path) { '/' + [uri]::EscapeDataString($Path) } else { '' }
    $url = "https://api.github.com/repos/$Owner/$Repo/contents$encodedPath?ref=$Branch"
    Invoke-RestMethod -Uri $url -Headers @{ 'User-Agent' = 'PowerShell' }
>>>>>>> 219692d4d8365ce716e613de71f39d4a231e0503
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

<<<<<<< HEAD
<# GUI ──────────────────────────────────────────── #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "$Repo Browser"
=======
# GUI Setup
$form = New-Object Windows.Forms.Form
$form.Text = "Repo Browser"
>>>>>>> 219692d4d8365ce716e613de71f39d4a231e0503
$form.Size = '500,400'
$form.StartPosition = 'CenterScreen'
$form.BackColor = '#1e1e1e'
$form.ForeColor = 'White'
<<<<<<< HEAD
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Welcome
$label = New-Object Windows.Forms.Label
$label.Text = 'Welcome to Apps Knowledge'
$label.Font = 'Segoe UI,18,style=Bold'
$label.AutoSize = $true
$label.BackColor = 'Transparent'
=======

$label = New-Object Windows.Forms.Label
$label.Text = 'Select a Folder to Download'
$label.AutoSize = $true
$label.Font = 'Segoe UI,14'
$label.Top = 20
$label.Left = 140
>>>>>>> 219692d4d8365ce716e613de71f39d4a231e0503
$form.Controls.Add($label)

<<<<<<< HEAD
# Fade
$form.Opacity = 0
$fade = New-Object Windows.Forms.Timer
$fade.Interval = 50
$fade.Add_Tick({ if ($form.Opacity -lt 1) { $form.Opacity += 0.1 } else { $fade.Stop() } })
$fade.Start()

# List
$list = New-Object Windows.Forms.ListBox
$list.Size = '300,200'
$list.Location = '90,80'
$list.Visible = $false
$form.Controls.Add($list)

# Button
$btn = New-Object Windows.Forms.Button
$btn.Text = 'Download Selected Folder'
$btn.Size = '200,30'
$btn.Location = '150,300'
$btn.BackColor = '#3a3d41'
$btn.ForeColor = 'White'
$btn.Visible = $false
$form.Controls.Add($btn)

# Load after 3s
$delay = New-Object Windows.Forms.Timer
$delay.Interval = 3000
$delay.Add_Tick({
    $delay.Stop()
    $label.Visible = $false
    try {
        $dirs = Get-GitHubContent | Where-Object type -eq 'dir'
        $dirs.name | ForEach-Object { $list.Items.Add($_) }
        $list.Visible = $btn.Visible = $true
    } catch {
        $code = $_.Exception.Response.StatusCode.value__ 2>$null
        [Windows.Forms.MessageBox]::Show("Error loading folders:`nHTTP $code`n$_",'GitHub Error')
        $form.Close()
    }
})
$delay.Start()

# Download logic
=======
$listBox = New-Object Windows.Forms.ListBox
$listBox.Size = '400,200'
$listBox.Location = '45,60'
$form.Controls.Add($listBox)

$btn = New-Object Windows.Forms.Button
$btn.Text = "Download Selected"
$btn.Size = '180,30'
$btn.Location = '160,280'
$form.Controls.Add($btn)

>>>>>>> 219692d4d8365ce716e613de71f39d4a231e0503
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
