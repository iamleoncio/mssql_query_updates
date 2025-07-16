<# CONFIG #>
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Headers = @{ 'User-Agent' = 'PowerShell-GUI-App' }

function Encode-Path ($Path) {
    ($Path -split '/') | ForEach-Object { [uri]::EscapeDataString($_) } -join '/'
}

function Get-GitHubContent ($Path = '') {
    $enc = if ($Path) { '/' + (Encode-Path $Path) } else { '' }
    $url = "https://api.github.com/repos/$Owner/$Repo/contents$enc?ref=$Branch"
    Invoke-RestMethod -Uri $url -Headers $Headers
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

<# GUI SETUP #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text            = "$Repo Browser"
$form.Size            = '500,400'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#1e1e1e'
$form.ForeColor       = 'White'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Welcome label
$label = New-Object Windows.Forms.Label
$label.Text      = 'Welcome to Apps Knowledge'
$label.Font      = 'Segoe UI,18,style=Bold'
$label.AutoSize  = $true
$label.BackColor = 'Transparent'
$form.Controls.Add($label)
$form.Add_Shown({ 
    $label.Left = ($form.ClientSize.Width  - $label.Width)  / 2
    $label.Top  = ($form.ClientSize.Height - $label.Height) / 2
})

# Fade-in effect
$form.Opacity = 0
$fade = New-Object Windows.Forms.Timer
$fade.Interval = 50
$fade.Add_Tick({ if ($form.Opacity -lt 1) { $form.Opacity += 0.1 } else { $fade.Stop() } })
$fade.Start()

# Folder list
$list = New-Object Windows.Forms.ListBox
$list.Size      = '300,200'
$list.Location  = '90,80'
$list.Visible   = $false
$form.Controls.Add($list)

# Download button
$btn = New-Object Windows.Forms.Button
$btn.Text       = 'Download Selected Folder'
$btn.Size       = '200,30'
$btn.Location   = '150,300'
$btn.BackColor  = '#3a3d41'
$btn.ForeColor  = 'White'
$btn.Visible    = $false
$form.Controls.Add($btn)

# Show folders after 3 seconds
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

# Button click to download selected folder
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

[void]$form.ShowDialog()
