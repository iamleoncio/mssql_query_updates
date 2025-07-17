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
        [System.Windows.Forms.StatusBar]$StatusBar
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
            $StatusBar.Text = "Discovering files... ($($allFiles.Count) found)"
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
$form.Text            = "AppsKnowledge - GitHub Repository Browser"
$form.Size            = '800,650'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#1e1e1e'
$form.ForeColor       = 'White'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Title Panel
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Size = New-Object System.Drawing.Size(800, 80)
$titlePanel.BackColor = '#2d2d30'
$titlePanel.Dock = 'Top'
$form.Controls.Add($titlePanel)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "GitHub Repository Browser"
$titleLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize  = $true
$titleLabel.Location  = New-Object System.Drawing.Point(20, 15)
$titlePanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$repoLabel.AutoSize  = $true
$repoLabel.Location  = New-Object System.Drawing.Point(20, 45)
$repoLabel.ForeColor = 'Silver'
$titlePanel.Controls.Add($repoLabel)

# Main Panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Size = New-Object System.Drawing.Size(800, 570)
$mainPanel.Location = New-Object System.Drawing.Point(0, 80)
$mainPanel.BackColor = '#1e1e1e'
$form.Controls.Add($mainPanel)

# Welcome Label
$welcomeLabel = New-Object System.Windows.Forms.Label
$welcomeLabel.Text      = "Welcome to AppsKnowledge"
$welcomeLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$welcomeLabel.AutoSize  = $true
$welcomeLabel.Location  = New-Object System.Drawing.Point(200, 50)
$welcomeLabel.ForeColor = 'White'
$welcomeLabel.BackColor = 'Transparent'
$mainPanel.Controls.Add($welcomeLabel)

# Folder ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View       = 'Details'
$listView.Size       = New-Object System.Drawing.Size(750, 350)
$listView.Location   = New-Object System.Drawing.Point(25, 150)
$listView.FullRowSelect = $true
$listView.MultiSelect   = $true
$listView.BackColor     = '#252526'
$listView.ForeColor     = 'White'
$listView.Font          = New-Object System.Drawing.Font("Segoe UI", 11)
$listView.BorderStyle   = 'FixedSingle'

# Add folder icon
try {
    $listView.SmallImageList = New-Object System.Windows.Forms.ImageList
    $listView.SmallImageList.ImageSize = New-Object System.Drawing.Size(24, 24)
    $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
    $listView.SmallImageList.Images.Add($folderIcon)
} catch {
    # Continue without icons if extraction fails
}

$listView.Columns.Add("Folders", 700) | Out-Null
$mainPanel.Controls.Add($listView)

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"
$statusBar.BackColor = '#007acc'
$statusBar.ForeColor = 'White'
$statusBar.Height = 24
$statusBar.Dock = 'Bottom'
$mainPanel.Controls.Add($statusBar)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size      = New-Object System.Drawing.Size(750, 25)
$progressBar.Location  = New-Object System.Drawing.Point(25, 510)
$progressBar.Style     = 'Marquee'
$progressBar.Visible   = $false
$mainPanel.Controls.Add($progressBar)

# Button Panel
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Size = New-Object System.Drawing.Size(750, 50)
$buttonPanel.Location = New-Object System.Drawing.Point(25, 550)
$buttonPanel.BackColor = 'Transparent'
$mainPanel.Controls.Add($buttonPanel)

# Download Button
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text       = 'Download Selected Folders'
$btnDownload.Size       = New-Object System.Drawing.Size(250, 40)
$btnDownload.Location   = New-Object System.Drawing.Point(50, 5)
$btnDownload.BackColor  = '#3276b1'
$btnDownload.ForeColor  = 'White'
$btnDownload.Enabled    = $false
$btnDownload.FlatStyle  = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$buttonPanel.Controls.Add($btnDownload)

# GitHub Link Button
$btnGitHub = New-Object System.Windows.Forms.Button
$btnGitHub.Text       = 'Open in GitHub'
$btnGitHub.Size       = New-Object System.Drawing.Size(150, 40)
$btnGitHub.Location   = New-Object System.Drawing.Point(320, 5)
$btnGitHub.BackColor  = '#4078c0'
$btnGitHub.ForeColor  = 'White'
$btnGitHub.FlatStyle  = 'Flat'
$btnGitHub.FlatAppearance.BorderSize = 0
$btnGitHub.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$buttonPanel.Controls.Add($btnGitHub)

# Refresh Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text       = 'Refresh'
$btnRefresh.Size       = New-Object System.Drawing.Size(150, 40)
$btnRefresh.Location   = New-Object System.Drawing.Point(490, 5)
$btnRefresh.BackColor  = '#3a3d41'
$btnRefresh.ForeColor  = 'White'
$btnRefresh.FlatStyle  = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$buttonPanel.Controls.Add($btnRefresh)

# Populate folder list
$loadFolders = {
    try {
        $statusBar.Text = "Connecting to GitHub..."
        $progressBar.Visible = $true
        $progressBar.Style = 'Marquee'
        $form.Refresh()
        
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
            if ($listView.SmallImageList -ne $null) {
                $item.ImageIndex = 0
            }
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

# Download selected folders
$btnDownload.Add_Click({
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Please select at least one folder',
            'Selection Required',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select download location"
    $dlg.RootFolder = 'MyComputer'
    $dlg.ShowNewFolderButton = $true
    
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
        $statusBar.Text = "Download canceled"
        return 
    }

    $totalFiles = 0
    $successCount = 0
    $foldersToDownload = $listView.SelectedItems
    
    try {
        # Setup progress UI
        $progressBar.Visible = $true
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 0
        $btnDownload.Enabled = $false
        $listView.Enabled = $false
        $statusBar.Text = "Preparing download..."
        $form.Refresh()
        
        # First pass: Count total files
        foreach ($item in $foldersToDownload) {
            $path = $item.Tag
            $files = Get-GitHubFileList -Path $path -ProgressBar $progressBar -StatusBar $statusBar
            $totalFiles += $files.Count
        }
        
        if ($totalFiles -eq 0) {
            $statusBar.Text = "No files found in selected folders"
            return
        }
        
        $progressBar.Maximum = $totalFiles
        $progressBar.Value = 0
        $counter = 0
        
        # Second pass: Download files
        foreach ($item in $foldersToDownload) {
            $folder = $item.Text
            $path = $item.Tag
            $statusBar.Text = "Processing folder: $folder"
            $form.Refresh()
            
            $files = Get-GitHubFileList -Path $path -ProgressBar $null -StatusBar $statusBar
            
            foreach ($file in $files) {
                $counter++
                $progressBar.Value = $counter
                $statusBar.Text = "Downloading file $counter/$totalFiles - $($file.RelativePath)"
                $form.Refresh()

                # FIX: Use proper path combining
                $basePath = Join-Path -Path $dlg.SelectedPath -ChildPath $folder
                $localPath = Join-Path -Path $basePath -ChildPath $file.RelativePath
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
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Successfully downloaded $successCount/$totalFiles files to:`n$($dlg.SelectedPath)",
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
