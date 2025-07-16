# ── CONFIG ───────────────────────────────────────────────────────────────
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'

# Required headers: GitHub rejects requests without User-Agent.
$Headers = @{
    'User-Agent' = 'PowerShellApp'
    'Accept'     = 'application/vnd.github.v3+json'
}

# Optional: Add GitHub Personal Access Token for authenticated requests
$Token = $env:GITHUB_TOKEN  # Set this environment variable or hardcode (not recommended)
if ($Token) {
    $Headers['Authorization'] = "token $Token"
}

# ── GITHUB HELPERS ───────────────────────────────────────────────────────
function Encode-Path([string]$Path) {
    if (-not $Path) { return '' }
    ($Path -split '/') |
        ForEach-Object { [uri]::EscapeDataString($_) } |
        Join-String -Separator '/'
}

function Get-GitHubContent([string]$Path = '') {
    $encPath = Encode-Path $Path
    $url = if ($encPath) {
        "https://api.github.com/repos/$Owner/$Repo/contents/$encPath?ref=$Branch"
    } else {
        "https://api.github.com/repos/$Owner/$Repo/contents?ref=$Branch"
    }
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -ErrorAction Stop
        return $response
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__ ?? 'Unknown'
        throw "Failed to fetch content from GitHub: HTTP $statusCode - $($_.Exception.Message)"
    }
}

function Download-GitHubFolder([string]$Path, [string]$Target, [System.Windows.Forms.Form]$Form) {
    $items = Get-GitHubContent $Path
    $totalItems = $items.Count
    $currentItem = 0

    # Create a progress bar
    $progressBar = New-Object Windows.Forms.ProgressBar
    $progressBar.Size = '300,20'
    $progressBar.Location = '100,280'
    $progressBar.Maximum = $totalItems
    $Form.Controls.Add($progressBar)

    foreach ($item in $items) {
        $currentItem++
        $progressBar.Value = $currentItem
        $Form.Text = "Downloading: $Path ($currentItem/$totalItems)"
        $dest = Join-Path $Target $item.name

        if ($item.type -eq 'file') {
            # Check if file exists
            if (Test-Path $dest) {
                $overwrite = [System.Windows.Forms.MessageBox]::Show(
                    "File '$($item.name)' already exists. Overwrite?",
                    'Confirm Overwrite',
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($overwrite -ne 'Yes') { continue }
            }
            try {
                Invoke-WebRequest -Uri $item.download_url -OutFile $dest -Headers $Headers -ErrorAction Stop
            } catch {
                throw "Failed to download '$($item.name)': $($_.Exception.Message)"
            }
        } elseif ($item.type -eq 'dir') {
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
            Download-GitHubFolder -Path $item.path -Target $dest -Form $Form
        }
    }
    $Form.Controls.Remove($progressBar)
}

# ── GUI SETUP ────────────────────────────────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text            = "$Repo Browser"
$form.Size            = New-Object Drawing.Size(500, 400)
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#1e1e1e'
$form.ForeColor       = 'White'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Welcome Label
$label = New-Object Windows.Forms.Label
$label.Text      = 'Welcome to Apps Knowledge'
$label.Font      = New-Object Drawing.Font('Segoe UI', 18, [Drawing.FontStyle]::Bold)
$label.AutoSize  = $true
$label.BackColor = 'Transparent'
$form.Controls.Add($label)

# Center the label dynamically
$form.Add_Resize({
    $label.Left = ($form.ClientSize.Width - $label.Width) / 2
    $label.Top  = ($form.ClientSize.Height - $label.Height) / 2
})

# Folder List
$list = New-Object Windows.Forms.ListBox
$list.Size      = New-Object Drawing.Size(320, 210)
$list.Location  = New-Object Drawing.Point(80, 80)
$list.Visible   = $false
$form.Controls.Add($list)

# Download Button
$btn = New-Object Windows.Forms.Button
$btn.Text       = 'Download Selected Folder'
$btn.Size       = New-Object Drawing.Size(220, 30)
$btn.Location   = New-Object Drawing.Point(140, 310)
$btn.BackColor  = '#3a3d41'
$btn.ForeColor  = 'White'
$btn.Visible    = $false
$form.Controls.Add($btn)

# ── Load top-level folders after 1s (reduced delay for better UX) ────────
$delay = New-Object Windows.Forms.Timer
$delay.Interval = 1000
$delay.Add_Tick({
    $delay.Stop()
    $label.Visible = $false
    try {
        $top = Get-GitHubContent | Where-Object { $_.type -eq 'dir' }
        if (-not $top) {
            [System.Windows.Forms.MessageBox]::Show('No folders found in the repository.', 'Info')
            $form.Close()
            return
        }
        $top.name | ForEach-Object { $list.Items.Add($_) }
        $list.Visible = $btn.Visible = $true
    } catch {
        $errorMsg = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Error loading folders:`n$errorMsg", 'GitHub Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
        $form.Close()
    }
})
$delay.Start()

# ── Button Action ───────────────────────────────────────────────────────
$btn.Add_Click({
    if (-not $list.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show('Please select a folder.', 'Warning',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $folder = $list.SelectedItem.ToString()
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select a destination folder for '$folder'"
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Download-GitHubFolder -Path $folder -Target $dlg.SelectedPath -Form $form
        [System.Windows.Forms.MessageBox]::Show(
            "$folder downloaded to:`n$($dlg.SelectedPath)", 'Success',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Download failed:`n$($_.Exception.Message)", 'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# ── Fade-in Effect ──────────────────────────────────────────────────────
$form.Opacity = 0
$fadeTimer = New-Object Windows.Forms.Timer
$fadeTimer.Interval = 50
$fadeTimer.Add_Tick({
    if ($form.Opacity -lt 1) {
        $form.Opacity += 0.1
    } else {
        $fadeTimer.Stop()
    }
})
$fadeTimer.Start()

[void]$form.ShowDialog()
