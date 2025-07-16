<# ── CONFIG ──────────────────────────────── #>
$Owner  = 'yourname'      # Replace with your GitHub username
$Repo   = 'ps-tools'      # Replace with your repo name
$Branch = 'main'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Headers = @{ 'User-Agent' = 'PS-GUI-App' }

<# ── GUI SETUP ───────────────────────────── #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "$Repo – Browser"
$form.Size             = New-Object System.Drawing.Size(500, 400)
$form.StartPosition    = "CenterScreen"
$form.BackColor        = "#1e1e1e"
$form.ForeColor        = "White"

$welcome               = New-Object System.Windows.Forms.Label
$welcome.Text          = "Welcome to Apps Knowledge"
$welcome.AutoSize      = $true
$welcome.Font          = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$welcome.Location      = New-Object System.Drawing.Point(50, 150)
$form.Controls.Add($welcome)

$lst                   = New-Object System.Windows.Forms.ListBox
$lst.Size              = New-Object System.Drawing.Size(300, 200)
$lst.Location          = New-Object System.Drawing.Point(90, 80)
$lst.Visible           = $false
$form.Controls.Add($lst)

$btn                   = New-Object System.Windows.Forms.Button
$btn.Text              = "Download Selected Folder"
$btn.Location          = New-Object System.Drawing.Point(150, 300)
$btn.Size              = New-Object System.Drawing.Size(200, 30)
$btn.BackColor         = "#3a3d41"
$btn.ForeColor         = "White"
$btn.Visible           = $false
$form.Controls.Add($btn)

<# ── Show folders after 5 seconds ────────── #>
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.add_Tick({
    $timer.Stop()
    $welcome.Visible = $false

    try {
        $url = "https://api.github.com/repos/$Owner/$Repo/contents?ref=$Branch"
        $data = Invoke-RestMethod -Uri $url -Headers $Headers
        ($data | Where-Object type -eq 'dir').name | ForEach-Object { $lst.Items.Add($_) }
        $lst.Visible = $true
        $btn.Visible = $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error reading repo: $_")
    }
})
$timer.Start()

<# ── Download folder recursively ─────────── #>
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

<# ── Button Click Action ─────────────────── #>
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
        [System.Windows.Forms.MessageBox]::Show("$folder downloaded to $($dlg.SelectedPath)")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Download failed: $_")
    }
})

[void]$form.ShowDialog()
