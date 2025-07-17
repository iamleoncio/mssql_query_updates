# CONFIG
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'
$Headers = @{ 'User-Agent' = 'PowerShellApp' }

function Encode-Path ($Path) {
    ($Path -split '/') | ForEach-Object { [uri]::EscapeDataString($_) } -join '/'
}

function Get-GitHubContent ($Path = '') {
    $enc = if ($Path) { '/' + (Encode-Path $Path) } else { '' }
    $url = "https://api.github.com/repos/$Owner/$Repo/contents$enc?ref=$Branch"
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -ErrorAction Stop
        return $response
    } catch {
        throw "Failed to access GitHub: $($_.Exception.Message)"
    }
}

function Get-GitHubFileList {
    param(
        [string]$Path,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel
    )
    $allFiles = [System.Collections.Generic.List[object]]::new()
    $stack = [System.Collections.Stack]::new()
    $stack.Push($Path)
    
    while ($stack.Count -gt 0) {
        $currentPath = $stack.Pop()
        $items = Get-GitHubContent -Path $currentPath
        
        foreach ($item in $items) {
            if ($item.type -eq 'file') {
                $relativePath = $item.path.Substring($Path.Length + 1)
                $allFiles.Add([PSCustomObject]@{
                    RelativePath = $relativePath
                    DownloadUrl = $item.download_url
                })
            } elseif ($item.type -eq 'dir') {
                $stack.Push($item.path)
            }
        }
        
        if ($ProgressBar) {
            $StatusLabel.Text = "Discovering files... ($($allFiles.Count) found)"
            $ProgressBar.Value = [Math]::Min($ProgressBar.Value + 1, $ProgressBar.Maximum)
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    return $allFiles
}

# GUI Setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text            = "$Repo Browser"
$form.Size            = '600,500'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#1e1e1e'
$form.ForeColor       = 'White'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "GitHub Repository Browser"
$titleLabel.Font      = 'Segoe UI,14,style=Bold'
$titleLabel.AutoSize  = $true
$titleLabel.Location  = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = 'Segoe UI,9'
$repoLabel.AutoSize  = $true
$repoLabel.Location  = New-Object System.Drawing.Point(20, 45)
$repoLabel.ForeColor = 'Silver'
$form.Controls.Add($repoLabel)

# Folder ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View       = 'Details'
$listView.Size       = New-Object System.Drawing.Size(550, 300)
$listView.Location   = New-Object System.Drawing.Point(20, 80)
$listView.FullRowSelect = $true
$listView.MultiSelect   = $false
$listView.BackColor     = '#252526'
$listView.ForeColor     = 'White'
$listView.BorderStyle   = 'FixedSingle'
$listView.Columns.Add("Folders", 500) | Out-Null
$form.Controls.Add($listView)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text      = "Loading folders..."
$statusLabel.Font      = 'Segoe UI,9'
$statusLabel.AutoSize  = $false
$statusLabel.Size      = New-Object System.Drawing.Size(400, 20)
$statusLabel.Location  = New-Object System.Drawing.Point(20, 390)
$statusLabel.ForeColor = 'Silver'
$form.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size      = New-Object System.Drawing.Size(550, 20)
$progressBar.Location  = New-Object System.Drawing.Point(20, 415)
$progressBar.Style     = 'Marquee'
$progressBar.Visible   = $false
$form.Controls.Add($progressBar)

# Download Button
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text       = 'Download Selected Folder'
$btnDownload.Size       = New-Object System.Drawing.Size(200, 35)
$btnDownload.Location   = New-Object System.Drawing.Point(200, 450)
$btnDownload.BackColor  = '#3276b1'
$btnDownload.ForeColor  = 'White'
$btnDownload.Enabled    = $false
$btnDownload.FlatStyle  = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnDownload)

# GitHub Link
$linkLabel = New-Object System.Windows.Forms.LinkLabel
$linkLabel.Text         = "View on GitHub"
$linkLabel.AutoSize     = $true
$linkLabel.Location     = New-Object System.Drawing.Point(420, 460)
$linkLabel.LinkColor    = '#58a6ff'
$linkLabel.ActiveLinkColor = '#58a6ff'
$linkLabel.LinkClicked += {
    Start-Process "https://github.com/$Owner/$Repo/tree/$Branch"
}
$form.Controls.Add($linkLabel)

# Populate folder list
$loadFolders = {
    try {
        $dirs = Get-GitHubContent | Where-Object { $_.type -eq 'dir' } | Sort-Object name
        if (-not $dirs) {
            $statusLabel.Text = "No folders found in repository"
            return
        }
        
        $listView.BeginUpdate()
        $listView.Items.Clear()
        foreach ($dir in $dirs) {
            $item = New-Object System.Windows.Forms.ListViewItem($dir.name)
            $item.Tag = $dir.path
            $listView.Items.Add($item) | Out-Null
        }
        $listView.EndUpdate()
        $statusLabel.Text = "Select a folder to download"
        $btnDownload.Enabled = $true
    } catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to load folders:`n$($_.Exception.Message)",
            'GitHub Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Download selected folder
$btnDownload.Add_Click({
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Please select a folder first',
            'Selection Required',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    $folder = $listView.SelectedItems[0].Text
    $path = $listView.SelectedItems[0].Tag
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select download location for '$folder'"
    
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    try {
        # Setup progress UI
        $progressBar.Visible = $true
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 0
        $btnDownload.Enabled = $false
        $listView.Enabled = $false
        $statusLabel.Text = "Preparing to download '$folder'..."
        [System.Windows.Forms.Application]::DoEvents()

        # Get file list
        $progressBar.Maximum = 100
        $progressBar.Value = 0
        $files = Get-GitHubFileList -Path $path -ProgressBar $progressBar -StatusLabel $statusLabel
        
        if (-not $files) {
            $statusLabel.Text = "No files found in '$folder'"
            return
        }

        # Download files
        $progressBar.Maximum = $files.Count
        $progressBar.Value = 0
        $counter = 0
        
        foreach ($file in $files) {
            $counter++
            $progressBar.Value = $counter
            $statusLabel.Text = "Downloading file $counter/$($files.Count) - $($file.RelativePath)"
            [System.Windows.Forms.Application]::DoEvents()

            $localPath = Join-Path $dlg.SelectedPath $file.RelativePath
            $dirPath = [System.IO.Path]::GetDirectoryName($localPath)
            
            if (-not (Test-Path $dirPath)) {
                New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            }
            
            try {
                Invoke-WebRequest -Uri $file.DownloadUrl -OutFile $localPath -Headers $Headers
            } catch {
                throw "Failed to download '$($file.RelativePath)': $($_.Exception.Message)"
            }
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Successfully downloaded $counter files to:`n$($dlg.SelectedPath)",
            'Download Complete',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        $statusLabel.Text = "Download completed successfully"
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Download failed:`n$($_.Exception.Message)",
            'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $statusLabel.Text = "Download failed: $($_.Exception.Message)"
    } finally {
        $progressBar.Visible = $false
        $btnDownload.Enabled = $true
        $listView.Enabled = $true
    }
})

# Load folders after form shows
$form.Add_Shown({
    $progressBar.Visible = $true
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    & $loadFolders
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    $progressBar.Visible = $false
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
