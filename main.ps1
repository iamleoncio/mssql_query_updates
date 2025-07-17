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
$form.Size            = '900,700'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#fff0f5'  # LavenderBlush background
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Pink theme colors
$primaryPink = '#ff69b4'         # HotPink
$darkPink = '#db7093'            # PaleVioletRed
$lightPink = '#ffb6c1'           # LightPink
$accentPink = '#ff1493'          # DeepPink
$textColor = '#4b0082'           # Indigo
$panelColor = '#fff0f5'          # LavenderBlush
$listBgColor = '#fffaf0'         # FloralWhite

# Title Panel
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Size = New-Object System.Drawing.Size(900, 100)
$titlePanel.BackColor = $primaryPink
$titlePanel.Dock = 'Top'
$form.Controls.Add($titlePanel)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "GitHub Repository Browser"
$titleLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = 'White'
$titleLabel.AutoSize  = $false
$titleLabel.Size      = New-Object System.Drawing.Size(800, 40)
$titleLabel.Location  = New-Object System.Drawing.Point(50, 15)
$titleLabel.TextAlign = 'MiddleCenter'
$titlePanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$repoLabel.ForeColor = 'White'
$repoLabel.AutoSize  = $false
$repoLabel.Size      = New-Object System.Drawing.Size(800, 30)
$repoLabel.Location  = New-Object System.Drawing.Point(50, 55)
$repoLabel.TextAlign = 'MiddleCenter'
$titlePanel.Controls.Add($repoLabel)

# Main Panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Size = New-Object System.Drawing.Size(860, 540)
$mainPanel.Location = New-Object System.Drawing.Point(20, 120)
$mainPanel.BackColor = $panelColor
$mainPanel.BorderStyle = 'FixedSingle'
$form.Controls.Add($mainPanel)

# Welcome Label
$welcomeLabel = New-Object System.Windows.Forms.Label
$welcomeLabel.Text      = "Welcome to AppsKnowledge"
$welcomeLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$welcomeLabel.ForeColor = $textColor
$welcomeLabel.AutoSize  = $true
$welcomeLabel.Location  = New-Object System.Drawing.Point(280, 20)
$mainPanel.Controls.Add($welcomeLabel)

# Description Label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text      = "Browse and download folders from GitHub"
$descLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 12)
$descLabel.ForeColor = $textColor
$descLabel.AutoSize  = $true
$descLabel.Location  = New-Object System.Drawing.Point(290, 60)
$mainPanel.Controls.Add($descLabel)

# Folder List Container
$listContainer = New-Object System.Windows.Forms.Panel
$listContainer.Size = New-Object System.Drawing.Size(800, 300)
$listContainer.Location = New-Object System.Drawing.Point(30, 100)
$listContainer.BackColor = $listBgColor
$listContainer.BorderStyle = 'FixedSingle'
$mainPanel.Controls.Add($listContainer)

# Folder ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View       = 'Details'
$listView.Size       = New-Object System.Drawing.Size(780, 280)
$listView.Location   = New-Object System.Drawing.Point(10, 10)
$listView.FullRowSelect = $true
$listView.MultiSelect   = $true
$listView.BackColor     = $listBgColor
$listView.ForeColor     = $textColor
$listView.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$listView.BorderStyle   = 'None'

# Add folder icon
try {
    $listView.SmallImageList = New-Object System.Windows.Forms.ImageList
    $listView.SmallImageList.ImageSize = New-Object System.Drawing.Size(24, 24)
    $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
    $listView.SmallImageList.Images.Add($folderIcon)
} catch {
    # Continue without icons if extraction fails
}

$listView.Columns.Add("Folders", 760) | Out-Null
$listContainer.Controls.Add($listView)

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"
$statusBar.BackColor = $darkPink
$statusBar.ForeColor = 'White'
$statusBar.Height = 24
$statusBar.Dock = 'Bottom'
$form.Controls.Add($statusBar)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size      = New-Object System.Drawing.Size(800, 25)
$progressBar.Location  = New-Object System.Drawing.Point(30, 420)
$progressBar.Style     = 'Marquee'
$progressBar.Visible   = $false
$progressBar.ForeColor = $accentPink
$mainPanel.Controls.Add($progressBar)

# Button Panel
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Size = New-Object System.Drawing.Size(800, 60)
$buttonPanel.Location = New-Object System.Drawing.Point(30, 460)
$buttonPanel.BackColor = 'Transparent'
$mainPanel.Controls.Add($buttonPanel)

# Download Button
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text       = 'DOWNLOAD SELECTED FOLDERS'
$btnDownload.Size       = New-Object System.Drawing.Size(300, 45)
$btnDownload.Location   = New-Object System.Drawing.Point(50, 5)
$btnDownload.BackColor  = $primaryPink
$btnDownload.ForeColor  = 'White'
$btnDownload.Enabled    = $false
$btnDownload.FlatStyle  = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnDownload.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonPanel.Controls.Add($btnDownload)

# GitHub Link Button
$btnGitHub = New-Object System.Windows.Forms.Button
$btnGitHub.Text       = 'VIEW ON GITHUB'
$btnGitHub.Size       = New-Object System.Drawing.Size(180, 45)
$btnGitHub.Location   = New-Object System.Drawing.Point(370, 5)
$btnGitHub.BackColor  = $lightPink
$btnGitHub.ForeColor  = $textColor
$btnGitHub.FlatStyle  = 'Flat'
$btnGitHub.FlatAppearance.BorderSize = 0
$btnGitHub.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnGitHub.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonPanel.Controls.Add($btnGitHub)

# Refresh Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text       = 'REFRESH'
$btnRefresh.Size       = New-Object System.Drawing.Size(180, 45)
$btnRefresh.Location   = New-Object System.Drawing.Point(570, 5)
$btnRefresh.BackColor  = $lightPink
$btnRefresh.ForeColor  = $textColor
$btnRefresh.FlatStyle  = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
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
            $item.ForeColor = $textColor
            $listView.Items.Add($item) | Out-Null
        }
        $listView.EndUpdate()
        $statusBar.Text = "$($dirs.Count) folders found - Select folders to download"
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
            'Please select at least one folder to download',
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

                # Proper path combining
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
    $statusBar.Text = "Refreshing folder list..."
    & $loadFolders
})

# Load folders after form shows
$form.Add_Shown({
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $statusBar.Text = "Loading repository content..."
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

# Add hover effects to buttons
$buttonHover = {
    $button = $sender
    $button.BackColor = $accentPink
    $button.ForeColor = 'White'
}

$buttonLeave = {
    $button = $sender
    if ($button.Text -eq 'DOWNLOAD SELECTED FOLDERS') {
        $button.BackColor = $primaryPink
    } else {
        $button.BackColor = $lightPink
        $button.ForeColor = $textColor
    }
}

$btnDownload.Add_MouseEnter($buttonHover)
$btnDownload.Add_MouseLeave($buttonLeave)
$btnGitHub.Add_MouseEnter($buttonHover)
$btnGitHub.Add_MouseLeave($buttonLeave)
$btnRefresh.Add_MouseEnter($buttonHover)
$btnRefresh.Add_MouseLeave($buttonLeave)

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
