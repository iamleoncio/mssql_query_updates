# GitHub-Themed SQL Runner GUI - Polished Version

# CONFIG - Replace with your repository details
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'
$GitHubToken = ''  # Optional GitHub token

# HEADERS
$Headers = @{ 'User-Agent' = 'PowerShellApp' }
if ($GitHubToken -ne '') {
    $Headers['Authorization'] = "token $GitHubToken"
}

# FORM STYLING
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$darkBackground = '#0d1117'
$lightText = '#c9d1d9'
$buttonBackground = '#238636'

$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Script Runner"
$form.Size = New-Object System.Drawing.Size(950, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = $darkBackground

# TREEVIEW
$treeView = New-Object System.Windows.Forms.TreeView
$treeView.Size = New-Object System.Drawing.Size(400, 460)
$treeView.Location = New-Object System.Drawing.Point(20, 20)
$treeView.CheckBoxes = $true
$treeView.BackColor = $darkBackground
$treeView.ForeColor = $lightText
$treeView.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# IMAGE LIST FOR TREE ICONS
$imageList = New-Object System.Windows.Forms.ImageList
$imageList.Images.Add("Folder", [System.Drawing.SystemIcons]::WinLogo.ToBitmap())
$imageList.Images.Add("SQL", [System.Drawing.SystemIcons]::Information.ToBitmap())
$treeView.ImageList = $imageList

# BUTTON LAYOUT
$buttonLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonLayout.Location = New-Object System.Drawing.Point(440, 20)
$buttonLayout.Size = New-Object System.Drawing.Size(470, 55)
$buttonLayout.FlowDirection = "LeftToRight"
$buttonLayout.BackColor = $darkBackground

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = 'RUN SELECTED SCRIPTS'
$btnRun.Size = New-Object System.Drawing.Size(180, 45)
$btnRun.BackColor = $buttonBackground
$btnRun.ForeColor = $lightText
$btnRun.FlatStyle = 'Flat'
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnRun.Enabled = $false
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand

$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text = 'DOWNLOAD SELECTED'
$btnDownload.Size = New-Object System.Drawing.Size(180, 45)
$btnDownload.BackColor = '#30363d'
$btnDownload.ForeColor = $lightText
$btnDownload.FlatStyle = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnDownload.Cursor = [System.Windows.Forms.Cursors]::Hand

$buttonLayout.Controls.Add($btnRun)
$buttonLayout.Controls.Add($btnDownload)

# CREDENTIAL INPUTS
$txtServer = New-Object System.Windows.Forms.TextBox
$txtServer.Location = New-Object System.Drawing.Point(440, 100)
$txtServer.Size = New-Object System.Drawing.Size(460, 30)
$txtServer.ForeColor = $lightText
$txtServer.BackColor = '#161b22'
$txtServer.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtServer.Text = 'localhost'

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(440, 140)
$txtUser.Size = New-Object System.Drawing.Size(220, 30)
$txtUser.ForeColor = $lightText
$txtUser.BackColor = '#161b22'
$txtUser.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtUser.Text = 'sa'

$txtPassword = New-Object System.Windows.Forms.TextBox
$txtPassword.Location = New-Object System.Drawing.Point(680, 140)
$txtPassword.Size = New-Object System.Drawing.Size(220, 30)
$txtPassword.ForeColor = $lightText
$txtPassword.BackColor = '#161b22'
$txtPassword.UseSystemPasswordChar = $true
$txtPassword.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# FUNCTION - FETCH TREE
function Get-SelectedFiles($node) {
    $results = @()
    if ($node.ImageKey -eq "SQL" -and $node.Checked) {
        $results += [PSCustomObject]@{ Name = $node.Text; DownloadUrl = $node.Tag }
    }
    foreach ($child in $node.Nodes) {
        $results += Get-SelectedFiles $child
    }
    return $results
}

function HasCheckedSqlFiles($node) {
    if ($node.ImageKey -eq "SQL" -and $node.Checked) { return $true }
    foreach ($child in $node.Nodes) {
        if (HasCheckedSqlFiles $child) { return $true }
    }
    return $false
}

function UpdateRunButtonState {
    $anyChecked = $false
    foreach ($node in $treeView.Nodes) {
        if (HasCheckedSqlFiles $node) {
            $anyChecked = $true; break
        }
    }
    $btnRun.Enabled = $anyChecked
}

function LoadGitHubTree {
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/git/trees/$Branch?recursive=1"
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $Headers
    $treeView.Nodes.Clear()
    $nodes = @{}
    foreach ($item in $response.tree | Where-Object { $_.type -eq 'blob' -and $_.path -like '*.sql' }) {
        $parts = $item.path -split '/'
        $parent = $treeView.Nodes
        $pathKey = ""
        foreach ($i in 0..($parts.Count - 2)) {
            $pathKey += $parts[$i]
            if (-not $nodes.ContainsKey($pathKey)) {
                $folderNode = $parent.Add($parts[$i])
                $folderNode.ImageKey = "Folder"
                $folderNode.SelectedImageKey = "Folder"
                $folderNode.BackColor = $darkBackground
                $folderNode.ForeColor = $lightText
                $folderNode.Font = New-Object System.Drawing.Font("Segoe UI", 10)
                $nodes[$pathKey] = $folderNode
            }
            $parent = $nodes[$pathKey].Nodes
        }
        $fileNode = $parent.Add($parts[-1])
        $fileNode.Tag = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$($item.path)"
        $fileNode.ImageKey = "SQL"
        $fileNode.SelectedImageKey = "SQL"
        $fileNode.BackColor = $darkBackground
        $fileNode.ForeColor = $lightText
        $fileNode.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    }
    $treeView.ExpandAll()
}

$treeView.Add_AfterCheck({ UpdateRunButtonState })

# RUN BUTTON CLICK
$btnRun.Add_Click({
    $files = @()
    foreach ($node in $treeView.Nodes) {
        $files += Get-SelectedFiles $node
    }

    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one SQL script to run", "No Files", "OK", "Information")
        return
    }

    $server = $txtServer.Text
    $user   = $txtUser.Text
    $pass   = $txtPassword.Text
    
    foreach ($file in $files) {
        try {
            $sql = Invoke-WebRequest -Uri $file.DownloadUrl -Headers $Headers -UseBasicParsing
            Invoke-Sqlcmd -ServerInstance $server -Username $user -Password $pass -Query $sql.Content
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error running: $($file.Name)`n$($_.Exception.Message)", "Execution Error", "OK", "Error")
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Execution complete.", "Done", "OK", "Information")
})

# DOWNLOAD BUTTON CLICK
$btnDownload.Add_Click({
    $files = @()
    foreach ($node in $treeView.Nodes) {
        $files += Get-SelectedFiles $node
    }
    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one SQL script to download", "No Files", "OK", "Information")
        return
    }

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderDialog.ShowDialog() -eq 'OK') {
        foreach ($file in $files) {
            try {
                $dest = Join-Path $folderDialog.SelectedPath $file.Name
                Invoke-WebRequest -Uri $file.DownloadUrl -OutFile $dest -Headers $Headers
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed: $($file.Name)`n$($_.Exception.Message)", "Download Error", "OK", "Error")
            }
        }
        [System.Windows.Forms.MessageBox]::Show("Download complete.", "Done", "OK", "Information")
    }
})

# ADD TO FORM
$form.Controls.Add($treeView)
$form.Controls.Add($buttonLayout)
$form.Controls.Add($txtServer)
$form.Controls.Add($txtUser)
$form.Controls.Add($txtPassword)

LoadGitHubTree
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
