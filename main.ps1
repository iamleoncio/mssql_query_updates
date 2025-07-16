# ── CONFIG ───────────────────────────────────────────────────────────────
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'

# Required headers: GitHub rejects requests without User‑Agent.
# We also add the API media‑type so GitHub doesn’t default to HTML.
$Headers = @{
    'User-Agent' = 'PowerShellApp'
    'Accept'     = 'application/vnd.github.v3+json'
}

# ── GITHUB HELPERS ───────────────────────────────────────────────────────
function Encode-Path([string]$Path) {
    if (-not $Path) { return '' }
    ($Path -split '/') |
        ForEach-Object { [uri]::EscapeDataString($_) } |
        -join '/'
}

function Get-GitHubContent([string]$Path = '') {
    # Build URL with exactly one slash before encoded path
    $encPath = Encode-Path $Path
    $url = if ($encPath) {
        "https://api.github.com/repos/$Owner/$Repo/contents/$encPath?ref=$Branch"
    } else {
        "https://api.github.com/repos/$Owner/$Repo/contents?ref=$Branch"
    }
    Invoke-RestMethod -Uri $url -Headers $Headers
}

function Download-GitHubFolder([string]$Path, [string]$Target) {
    $items = Get-GitHubContent $Path
    foreach ($item in $items) {
        $dest = Join-Path $Target $item.name
        if ($item.type -eq 'file') {
            Invoke-WebRequest -Uri $item.download_url -OutFile $dest -Headers $Headers
        } elseif ($item.type -eq 'dir') {
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
            Download-GitHubFolder -Path $item.path -Target $dest
        }
    }
}

# ── GUI SETUP ────────────────────────────────────────────────────────────
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

# Welcome
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

# Fade‑in
$form.Opacity = 0
$fadeTimer = New-Object Windows.Forms.Timer
$fadeTimer.Interval = 50
$fadeTimer.Add_Tick({
    if ($form.Opacity -lt 1) { $form.Opacity += 0.1 } else { $fadeTimer.Stop() }
})
$fadeTimer.Start()

# Folder list
$list = New-Object Windows.Forms.ListBox
$list.Size      = '320,210'
$list.Location  = '80,80'
$list.Visible   = $false
$form.Controls.Add($list)

# Download button
$btn = New-Object Windows.Forms.Button
$btn.Text       = 'Download Selected Folder'
$btn.Size       = '220,30'
$btn.Location   = '140,310'
$btn.BackColor  = '#3a3d41'
$btn.ForeColor  = 'White'
$btn.Visible    = $false
$form.Controls.Add($btn)

# ── Load top‑level folders after 3 s ────────────────────────────────────
$delay = New-Object Windows.Forms.Timer
$delay.Interval = 3000
$delay.Add_Tick({
    $delay.Stop()
    $label.Visible = $false
    try {
        $top = Get-GitHubContent | Where-Object { $_.type -eq 'dir' }
        $top.name | ForEach-Object { $list.Items.Add($_) }
        $list.Visible = $btn.Visible = $true
    } catch {
        $code = $_.Exception.Response.StatusCode.value__ 2>$null
        [Windows.Forms.MessageBox]::Show("Error loading folders:`nHTTP $code`n$_",
                                         'GitHub Error',
                                         [Windows.Forms.MessageBoxButtons]::OK,
                                         [Windows.Forms.MessageBoxIcon]::Error)
        $form.Close()
    }
})
$delay.Start()

# ── Button action ───────────────────────────────────────────────────────
$btn.Add_Click({
    if (-not $list.SelectedItem) {
        [Windows.Forms.MessageBox]::Show('Select a folder first.')
        return
    }

    $folder = $list.SelectedItem.ToString()
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Download-GitHubFolder -Path $folder -Target $dlg.SelectedPath
        [Windows.Forms.MessageBox]::Show("$folder downloaded to:`n$($dlg.SelectedPath)",
                                         'Success',
                                         [Windows.Forms.MessageBoxButtons]::OK,
                                         [Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [Windows.Forms.MessageBox]::Show("Download failed:`n$_",
                                         'Error',
                                         [Windows.Forms.MessageBoxButtons]::OK,
                                         [Windows.Forms.MessageBoxIcon]::Error)
    }
})

[void]$form.ShowDialog()
