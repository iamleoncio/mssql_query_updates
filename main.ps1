<# ── CONFIG ──────────────────────────────── #>
$Owner  = 'yourname'      # ← replace with your GitHub username
$Repo   = 'ps-tools'      # ← replace with your repo name
$Branch = 'main'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Headers = @{ 'User-Agent' = 'PowerShell-GUI-App' }

<# ── GUI SETUP ──────────────────────────────── #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "$Repo – App Browser"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#1e1e1e"
$form.ForeColor = "White"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$welcome = New-Object System.Windows.Forms.Label
$welcome.Text = "Welcome to Apps Knowledge"
$welcome.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$welcome.ForeColor = "White"
$welcome.AutoSize = $true
$welcome.BackColor = 'Transparent'
$form.Controls.Add($welcome)

# Center the label dynamically
$welcome.Add_Shown({
    $welcome.Left = ($form.ClientSize.Width - $welcome.Width) / 2
    $welcome.Top = ($form.ClientSize.Height - $welcome.Height) / 2
})

# Add animation (fade-in effect)
$form.Opacity = 0
$fadeTimer = New-Object System.Windows.Forms.Timer
$fadeTimer.Interval = 50
$fadeTimer.Add_Tick({
    if ($form.Opacity -lt 1) {
        $form.Opacity += 0.1
    } else {
        $fadeTimer.Stop()
    }
})
$fadeTimer.Start()

<# ── LISTBOX ──────────────────────────────── #>
$lst = New-Object System.Windows.Forms.ListBox
$lst.Size = New-Object System.Drawing.Size(300, 200)
$lst.Location = New-Object System.Drawing.Point(90, 80)
$lst.Visible = $false
$form.Controls.Add($lst)

<# ── DOWNLOAD BUTTON ──────────────────────── #>
$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Download Selected Folder"
$btn.Size = New-Object System.Drawing.Size(200, 30)
$btn.Location = New-Object System.Drawing.Point(150, 300)
$btn.BackColor = "#3a3d41"
$btn.ForeColor = "White"
$btn.Visible = $false
$form.Controls.Add($btn)

<# ── LOAD FOLDERS AFTER 3 SECONDS ─────────── #>
$delayTimer = New-Object System.Windows.Forms.Timer
$delayTimer.Interval = 3000
$delayTimer.Add_Tick({
    $delayTimer.Stop()
    $welcome.Visible = $false

    try {
        $url = "https://api.github.com/repos/$Owner/$Repo/contents?ref=$Branch"
        $response = Invoke-RestMethod -Uri $url -Headers $Headers

        if ($response -isnot [System.Array]) {
            throw "Unexpected response format"
        }

        ($response | Where-Object type -eq 'dir').name | ForEach-Object { $lst.Items.Add($_) }
        $lst.Visible = $true
        $btn.Visible = $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load folders from GitHub.`n$_", "Error", "OK", "Error")
        $form.Close()
    }
})
$delayTimer.Start()

<# ── DOWNLOAD FUNCTION ─────────────────────── #>
function Get-Folder {
    param($Path, $Target)
    $items = Invoke-RestMethod "https://api.github.com/repos/$Owner/$Repo/contents/$Path?ref=$Branch" -Headers $Headers
    foreach ($item in $items) {
        $destPath = Join-Path $Target $item.name
        if ($item.type -eq 'file') {
            Invoke-WebRequest $item.download_url -OutFile $destPath -Headers $Headers
        } elseif ($item.type -eq 'dir') {
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath | Out-Null
            }
            Get-Folder -Path $item.path -Target $destPath
        }
    }
}

<# ── BUTTON ACTION ─────────────────────────── #>
$btn.Add_Click({
    if (-not $lst.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a folder first.")
        return
    }

    $folder = $lst.SelectedItem.ToString()
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Get-Folder -Path $folder -Target $dlg.SelectedPath
        [System.Windows.Forms.MessageBox]::Show("$folder downloaded to:`n$($dlg.SelectedPath)", "Success")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Download failed: $_", "Error", "OK", "Error")
    }
})

<# ── RUN FORM ──────────────────────────────── #>
[void]$form.ShowDialog()
