# CONFIG - Verify these details match your GitHub repository
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'
$GitHubToken = ''  # Optional: Add personal access token if needed
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create headers with authentication if token is provided
$Headers = @{
    'User-Agent' = 'PowerShellApp'
    'Accept' = 'application/vnd.github.v3+json'
}
if (-not [string]::IsNullOrEmpty($GitHubToken)) {
    $Headers['Authorization'] = "token $GitHubToken"
}

function Get-GitHubContent ($Path = '') {
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/contents"
    
    # Add path if specified
    if ($Path) {
        $apiUrl += "/$([uri]::EscapeDataString($Path))"
    }
    
    # Add branch parameter
    $apiUrl += "?ref=$([uri]::EscapeDataString($Branch))"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $Headers -ErrorAction Stop
        return $response
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMsg = if ($statusCode) {
            "HTTP $statusCode : $($_.Exception.Response.StatusDescription)"
        } else {
            $_.Exception.Message
        }
        throw "GitHub API Error: $errorMsg`nURL: $apiUrl"
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

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text            = "$Repo Browser"
$form.Size            = '700,600'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#1e1e1e'
$form.ForeColor       = 'White'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Title Panel
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Size = New-Object System.Drawing.Size(700, 70)
$titlePanel.BackColor = '#2d2d30'
$titlePanel.Dock = 'Top'
$form.Controls.Add($titlePanel)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "GitHub Repository Browser"
$titleLabel.Font      = 'Segoe UI,16,style=Bold'
$titleLabel.AutoSize  = $true
$titleLabel.Location  = New-Object System.Drawing.Point(20, 20)
$titlePanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = 'Segoe UI,10'
$repoLabel.AutoSize  = $true
$repoLabel.Location  = New-Object System.Drawing.Point(20, 45)
$repoLabel.ForeColor = 'Silver'
$titlePanel.Controls.Add($repoLabel)

# Folder ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View       = 'Details'
$listView.Size       = New-Object System.Drawing.Size(650, 350)
$listView.Location   = New-Object System.Drawing.Point(25, 85)
$listView.FullRowSelect = $true
$listView.MultiSelect   = $false
$listView.BackColor     = '#252526'
$listView.ForeColor     = 'White'
$listView.BorderStyle   = 'FixedSingle'
$listView.Columns.Add("Folders", 630) | Out-Null
$form.Controls.Add($listView)

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"
$statusBar.BackColor = '#007acc'
$statusBar.ForeColor = 'White'
$statusBar.Height = 24
$statusBar.Dock = 'Bottom'
$form.Controls.Add($statusBar)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size      = New-Object System.Drawing.Size(650, 25)
$progressBar.Location  = New-Object System.Drawing.Point(25, 450)
$progressBar.Style     = 'Marquee'
$progressBar.Visible   = $false
$form.Controls.Add($progressBar)

# Download Button
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text       = 'Download Selected Folder'
$btnDownload.Size       = New-Object System.Drawing.Size(250, 40)
$btnDownload.Location   = New-Object System.Drawing.Point(50, 490)
$btnDownload.BackColor  = '#3276b1'
$btnDownload.ForeColor  = 'White'
$btnDownload.Enabled    = $false
$btnDownload.FlatStyle  = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.Font = 'Segoe UI,10,style=Bold'
$form.Controls.Add($btnDownload)

# GitHub Link Button
$btnGitHub = New-Object System.Windows.Forms.Button
$btnGitHub.Text       = 'Open in GitHub'
$btnGitHub.Size       = New-Object System.Drawing.Size(150, 40)
$btnGitHub.Location   = New-Object System.Drawing.Point(320, 490)
$btnGitHub.BackColor  = '#4078c0'
$btnGitHub.ForeColor  = 'White'
$btnGitHub.FlatStyle  = 'Flat'
$btnGitHub.FlatAppearance.BorderSize = 0
$btnGitHub.Font = 'Segoe UI,10'
$form.Controls.Add($btnGitHub)

# Refresh Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text       = 'Refresh'
$btnRefresh.Size       = New-Object System.Drawing.Size(150, 40)
$btnRefresh.Location   = New-Object System.Drawing.Point(490, 490)
$btnRefresh.BackColor  = '#3a3d41'
$btnRefresh.ForeColor  = 'White'
$btnRefresh.FlatStyle  = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = 'Segoe UI,10'
$form.Controls.Add($btnRefresh)

# Populate folder list
$loadFolders = {
    try {
        $statusBar.Text = "Connecting to GitHub..."
        $progressBar.Visible = $true
        $progressBar.Style = 'Marquee'
        $form.Refresh()
        
        # Directly fetch content without repository test
        $content = Get-GitHubContent
        $dirs = $content | Where-Object { $_.type -eq 'dir' } | Sort-Object name
        
        if (-not $dirs) {
            $statusBar.Text = "No folders found in repository"
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
        $statusBar.Text = "$($dirs.Count) folders found"
        $btnDownload.Enabled = $true
    } catch {
        $statusBar.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "GitHub API Error:`n$($_.Exception.Message)",
            'Connection Failed',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } finally {
        $progressBar.Visible = $false
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
    $dlg.RootFolder = 'MyComputer'
    $dlg.ShowNewFolderButton = $true
    
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
        $statusBar.Text = "Download canceled"
        return 
    }

    try {
        # Setup progress UI
        $progressBar.Visible = $true
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 0
        $btnDownload.Enabled = $false
        $listView.Enabled = $false
        $statusBar.Text = "Preparing to download '$folder'..."
        $form.Refresh()

        # Get file list
        $files = Get-GitHubFileList -Path $path -ProgressBar $progressBar -StatusLabel $statusBar
        
        if (-not $files) {
            $statusBar.Text = "No files found in '$folder'"
            return
        }

        # Download files
        $progressBar.Maximum = $files.Count
        $progressBar.Value = 0
        $counter = 0
        $successCount = 0
        
        foreach ($file in $files) {
            $counter++
            $progressBar.Value = $counter
            $statusBar.Text = "Downloading file $counter/$($files.Count) - $($file.RelativePath)"
            $form.Refresh()

            $localPath = Join-Path $dlg.SelectedPath $file.RelativePath
            $dirPath = [System.IO.Path]::GetDirectoryName($localPath)
            
            if (-not (Test-Path $dirPath)) {
                New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            }
            
            try {
                Invoke-WebRequest -Uri $file.DownloadUrl -OutFile $localPath -Headers $Headers -UserAgent "PowerShellApp"
                $successCount++
            } catch {
                $statusBar.Text = "Error downloading $($file.RelativePath): $($_.Exception.Message)"
            }
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Successfully downloaded $successCount/$($files.Count) files to:`n$($dlg.SelectedPath)",
            'Download Complete',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        $statusBar.Text = "Download completed: $successCount files"
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Download failed:`n$($_.Exception.Message)",
            'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $statusBar.Text = "Download failed: $($_.Exception.Message)"
    } finally {
        $progressBar.Visible = $false
        $btnDownload.Enabled = $true
        $listView.Enabled = $true
    }
})

# GitHub button handler
$btnGitHub.Add_Click({
    Start-Process "https://github.com/$Owner/$Repo/tree/$Branch"
})

# Refresh button handler
$btnRefresh.Add_Click({
    $btnDownload.Enabled = $false
    & $loadFolders
})

# Load folders after form shows
$form.Add_Shown({
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    & $loadFolders
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
})

# Handle form closing
$form.Add_FormClosing({
    if ($progressBar.Visible) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please wait until current operation completes",
            "Operation in Progress",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        $_.Cancel = $true
    }
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
