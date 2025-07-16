<# ── CONFIG ──────────────────────────────── #>
$Owner  = 'iamleoncio'           # GitHub username
$Repo   = 'mssql_query_updates'  # repo name
$Branch = 'main'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Headers = @{ 'User-Agent' = 'PS-GUI-App' }   # add a PAT here if the repo ever becomes private

function Encode-Path ($Path) {
    # encode each segment so spaces or # etc. won’t break the API call
    ($Path -split '/') | ForEach-Object { [uri]::EscapeDataString($_) } -join '/'
}

function Get-GhJson ($Path = '') {
    $encPath = if ($Path) { '/' + (Encode-Path $Path) } else { '' }
    $url = "https://api.github.com/repos/$Owner/$Repo/contents$encPath?ref=$Branch"
    Invoke-RestMethod -Uri $url -Headers $Headers
}

<# ── GUI SETUP ──────────────────────────────── #>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "$Repo – App Browser"
$form.Size = [Drawing.Size]::new(500,400)
$form.StartPosition = 'CenterScreen'
$form.BackColor = '#1e1e1e'
$form.ForeColor = 'White'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$welcome = New-Object Windows.Forms.Label
$welcome.Text      = 'Welcome to Apps Knowledge'
$welcome.Font      = [Drawing.Font]::new('Segoe UI',18,[Drawing.FontStyle]::Bold)
$welcome.AutoSize  = $true
$welcome.BackColor = 'Transparent'
$form.Controls.Add($welcome)

$form.Add_Shown({
    $welcome.Left = ($form.ClientSize.Width  - $welcome.Width)  / 2
    $welcome.Top  = ($form.ClientSize.Height - $welcome.Height) / 2
})

$form.Opacity = 0.0
$fade = New-Object Windows.Forms.Timer
$fade.Interval = 50
$fade.Add_Tick({
    if ($form.Opacity -lt 1) { $form.Opacity += 0.1 } else { $fade.Stop() }
})
$fade.Start()

$lst = New-Object Windows.Forms.ListBox
$lst.Size     = [Drawing.Size]::new(300,200)
$lst.Location = [Drawing.Point]::new(90,80)
$lst.Visible  = $false
$form.Controls.Add($lst)

$btn = New-Object Windows.Forms.Button
$btn.Text      = 'Download Selected Folder'
$btn.Size      = [Drawing.Size]::new(200,30)
$btn.Location  = [Drawing.Point]::new(150,300)
$btn.BackColor = '#3a3d41'
$btn.ForeColor = 'White'
$btn.Visible   = $false
$form.Controls.Add($btn)

<# ── populate list after 3 s ────────────────── #>
$delay = New-Object Windows.Forms.Timer
$delay.Interval = 3000
$delay.Add_Tick({
    $delay.Stop()
    $welcome.Visible = $false
    try {
        $items = Get-GhJson
        ($items | Where-Object type -eq 'dir').name | ForEach-Object { $lst.Items.Add($_) }
        $lst.Visible = $btn.Visible = $true
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        [Windows.Forms.MessageBox]::Show("GitHub returned HTTP $code`n$_",'GitHub error',
                                         [Windows.Forms.MessageBoxButtons]::OK,
                                         [Windows.Forms.MessageBoxIcon]::Error)
        $form.Close()
    }
})
$delay.Start()

<# ── recursive download ────────────────────── #>
function Get-Folder {
    param($Path,$Target)
    $items = Get-GhJson $Path
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

$btn.Add_Click({
    if (-not $lst.SelectedItem) {
        [Windows.Forms.MessageBox]::Show('Select a folder first.'); return
    }
    $folder = $lst.SelectedItem.ToString()
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -ne 'OK') { return }

    try {
        Get-Folder -Path $folder -Target $dlg.SelectedPath
        [Windows.Forms.MessageBox]::Show("$folder downloaded to:`n$($dlg.SelectedPath)",
                                         'Success',
                                         [Windows.Forms.MessageBoxButtons]::OK,
                                         [Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        [Windows.Forms.MessageBox]::Show("Download failed (HTTP $code):`n$_",
                                         'Error',
                                         [Windows.Forms.MessageBoxButtons]::OK,
                                         [Windows.Forms.MessageBoxIcon]::Error)
    }
})

[void]$form.ShowDialog()
