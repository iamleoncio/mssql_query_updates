# CONFIG
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'
$GitHubToken = ''
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Headers
$Headers = @{ 'User-Agent' = 'PowerShellApp'; 'Accept' = 'application/vnd.github.v3+json' }
if ($GitHubToken) { $Headers['Authorization'] = "token $GitHubToken" }

# Global credentials
$global:SqlCredentials = $null

# Get GitHub content
function Get-GitHubContent($Path = '') {
    $url = "https://api.github.com/repos/$Owner/$Repo/contents/$Path?ref=$Branch"
    try { Invoke-RestMethod -Uri $url -Headers $Headers } catch {
        [System.Windows.Forms.MessageBox]::Show("GitHub Error: $($_.Exception.Message)", "Error")
    }
}

# Get .sql files
function Get-SqlFiles($Folder) {
    (Get-GitHubContent $Folder) | Where-Object { $_.type -eq 'file' -and $_.name -like '*.sql' }
}

# Run SQL script
function Invoke-SqlScript($Content, $Server, $Database, $User, $Pass) {
    try {
        $connStr = "Server=$Server;Database=$Database;User ID=$User;Password=$Pass;"
        $conn = New-Object System.Data.SqlClient.SqlConnection $connStr
        $conn.Open()
        $batches = $Content -split "\bGO\b"
        foreach ($batch in $batches) {
            if ($batch.Trim()) {
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $batch
                $cmd.ExecuteNonQuery()
            }
        }
        $conn.Close()
        return $true
    } catch { return $false }
}

# GUI
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Script Runner"
$form.Size = '700,600'
$form.StartPosition = 'CenterScreen'
$form.BackColor = 'WhiteSmoke'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Credentials Button
$btnCreds = New-Object System.Windows.Forms.Button
$btnCreds.Text = "Set Credentials"
$btnCreds.Width = 150
$btnCreds.Top = 20
$btnCreds.Left = 20
$form.Controls.Add($btnCreds)

# TreeView
$tree = New-Object System.Windows.Forms.TreeView
$tree.CheckBoxes = $true
$tree.Width = 640
$tree.Height = 400
$tree.Top = 60
$tree.Left = 20
$form.Controls.Add($tree)

# Run Button
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Selected Scripts"
$btnRun.Width = 180
$btnRun.Top = 480
$btnRun.Left = 20
$form.Controls.Add($btnRun)

# Load folders
function Load-Repo {
    $tree.Nodes.Clear()
    foreach ($item in Get-GitHubContent) {
        if ($item.type -eq 'dir') {
            $node = New-Object System.Windows.Forms.TreeNode $item.name
            $node.Tag = $item.path
            $tree.Nodes.Add($node)
        }
    }
}
Load-Repo

# Expand folder to show SQL files
$tree.Add_BeforeExpand({
    $node = $_.Node
    $node.Nodes.Clear()
    foreach ($file in Get-SqlFiles $node.Tag) {
        $child = New-Object System.Windows.Forms.TreeNode $file.name
        $child.Tag = $file.download_url
        $node.Nodes.Add($child)
    }
})

# Show credentials form
function Get-Creds {
    $f = New-Object System.Windows.Forms.Form -Property @{ Text = "Credentials"; Size = '300,230'; StartPosition = 'CenterParent' }
    $fields = "Server","Database","Username","Password"
    $txts = @()
    for ($i = 0; $i -lt $fields.Length; $i++) {
        $lbl = New-Object System.Windows.Forms.Label -Property @{ Text = $fields[$i]; Top = 20+($i*40); Left = 10; Width = 70 }
        $txt = New-Object System.Windows.Forms.TextBox -Property @{ Top = 20+($i*40); Left = 90; Width = 180 }
        if ($fields[$i] -eq "Password") { $txt.UseSystemPasswordChar = $true }
        $txts += $txt
        $f.Controls.AddRange(@($lbl, $txt))
    }
    $ok = New-Object System.Windows.Forms.Button -Property @{ Text = "OK"; Top = 180; Left = 190; DialogResult = 'OK' }
    $f.Controls.Add($ok)
    $f.AcceptButton = $ok
    if ($f.ShowDialog() -eq 'OK') {
        return @{ Server=$txts[0].Text; Database=$txts[1].Text; Username=$txts[2].Text; Password=$txts[3].Text }
    }
}

# Set credentials
$btnCreds.Add_Click({ $global:SqlCredentials = Get-Creds })

# Run checked scripts
$btnRun.Add_Click({
    if (-not $global:SqlCredentials) {
        [System.Windows.Forms.MessageBox]::Show("Set credentials first.", "Required")
        return
    }
    $selected = @()
    foreach ($node in $tree.Nodes) {
        foreach ($fileNode in $node.Nodes) {
            if ($fileNode.Checked) { $selected += $fileNode }
        }
    }
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one script.", "None selected")
        return
    }
    foreach ($f in $selected) {
        $content = (Invoke-WebRequest -Uri $f.Tag -Headers $Headers).Content
        $ok = Invoke-SqlScript $content `
            $global:SqlCredentials.Server `
            $global:SqlCredentials.Database `
            $global:SqlCredentials.Username `
            $global:SqlCredentials.Password
        if ($ok) { Write-Host "$($f.Text): Success" } else { Write-Host "$($f.Text): Failed" }
    }
    [System.Windows.Forms.MessageBox]::Show("Execution complete.", "Done")
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()
