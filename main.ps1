<# ── CONFIG ────────────────────────────────────────────────────────────── #>
$Owner  = 'yourname'          # GitHub user/org
$Repo   = 'ps-tools'          # repository
$Branch = 'main'              # branch to read from
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Headers = @{ 'User-Agent' = 'PS-GUI' }

<# ── GUI SETUP ─────────────────────────────────────────────────────────── #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "$Repo – Browser"
$form.Size             = [Drawing.Size]::new(500,400)
$form.StartPosition    = 'CenterScreen'
$form.BackColor        = '#1e1e1e'
$form.ForeColor        = 'White'

$welcome               = New-Object System.Windows.Forms.Label
$welcome.Text          = 'Welcome to Apps Knowledge'
$welcome.AutoSize      = $true
$welcome.Font          = [Drawing.Font]::new('Segoe UI',18,[Drawing.FontStyle]::Bold)
$welcome.Location      = [Drawing.Point]::new(40,150)
$form.Controls.Add($welcome)

$lst                   = New-Object System.Windows.Forms.ListBox
$lst.Size              = [Drawing.Size]::new(300,200)
$lst.Location          = [Drawing.Point]::new(90,80)
$lst.Visible           = $false
$form.Controls.Add($lst)

$btn                   = New-Object System.Windows.Forms.Button
$btn.Text              = 'Download Selected Folder'
$btn.Location          = [Drawing.Point]::new(150,300)
$btn.BackColor         = '#3a3d41'
$btn.ForeColor         = 'White'
$btn.Visible           = $false
$form.Controls.Add($btn)

<# ── TIMER (5 s) ────────────────────────────────────────────────────────── #>
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.add_Tick({
    $timer.Stop()
    $welcome.Visible = $false

    # Fetch folder list
    try {
        $url  = "https://api.github.com/repos/$Owner/$Repo/contents?ref=$Branch"
        $data = Invoke-RestMethod -Uri $url -Headers $Headers
        ($data | Where-Object type -eq 'dir').name | ForEach-Object { $lst.Items.Add($_) }
        $lst.Visible  = $true
        $btn.Visible  = $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Couldn’t read repo: $_")
    }
})
$timer.Start()

<# ── RECURSIVE DOWNLOAD ────────────────────────────────────────────────── #>
function Get-Folder {
    param($Path,$Target)
    $items = Invoke-RestMethod "https://api.github.com/repos/$Owner/$Repo/contents/$Path?ref=$Branch" -Headers $Headers
    foreach ($i in $items) {
        if ($i.type -eq 'file') {
            $dest = Join-Path $Target $i.name
            Invoke-WebRequest $i.download_url -OutFile $dest -Headers $Headers
        } elseif ($i.type -eq 'dir') {
            $sub  = Join-Path $Target $i.name
            if (-not (Test-Path $sub)) { New-Item -ItemType Directory -Path $sub | Out-Null }
            Get-Folder -Path $i.path -Target $sub
        }
    }
}

<# ── DOWNLOAD BUTTON ───────────────────────────────────────────────────── #>
$btn.Add_Click({
    if (-not $lst.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show('Select a folder first.'); return
    }
    $folder = $lst.SelectedItem.ToString()
    $dlg    = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Get-Folder -Path $folder -Target $dlg.SelectedPath
        [System.Windows.Forms.MessageBox]::Show("“$folder” downloaded to $($dlg.SelectedPath)")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Download failed: $_")
    }
})

[void]$form.ShowDialog()
