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
$form.Text            = "GitHub Repository Browser"
$form.Size            = '850,700'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = '#121212'  # Dark background
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.Padding         = New-Object System.Windows.Forms.Padding(20)

# macOS/iOS-inspired color palette
$darkBackground   = '#121212'     # Dark background
$cardBackground   = '#1c1c1e'     # Card background
$primaryBlue      = '#0a84ff'     # iOS blue
$lightText        = '#ffffff'     # White text
$secondaryText    = '#8e8e93'     # Gray text
$progressBlue     = '#5e5ce6'     # Purple-blue for progress
$buttonBackground = '#2c2c2e'     # Button background
$hoverBlue        = '#64d2ff'     # Light blue for hover

# Main Layout Panel
$mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$mainLayout.Dock = 'Fill'
$mainLayout.ColumnCount = 1
$mainLayout.RowCount = 4
$mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 40))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$form.Controls.Add($mainLayout)

# Header Panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = 'Fill'
$headerPanel.BackColor = $darkBackground
$headerPanel.AutoSize = $true
$mainLayout.Controls.Add($headerPanel, 0, 0)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "GitHub Repository Browser"
$titleLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $lightText
$titleLabel.AutoSize  = $true
$titleLabel.Location  = New-Object System.Drawing.Point(20, 20)
$headerPanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 11)
$repoLabel.ForeColor = $secondaryText
$repoLabel.AutoSize  = $true
$repoLabel.Location  = New-Object System.Drawing.Point(20, 65)
$headerPanel.Controls.Add($repoLabel)

# Welcome Card
$welcomeCard = New-Object System.Windows.Forms.Panel
$welcomeCard.Dock = 'Fill'
$welcomeCard.BackColor = $cardBackground
$welcomeCard.Padding = New-Object System.Windows.Forms.Padding(20)
$welcomeCard.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$mainLayout.Controls.Add($welcomeCard, 0, 1)

# Welcome Label
$welcomeLabel = New-Object System.Windows.Forms.Label
$welcomeLabel.Text      = "Welcome to AppsKnowledge"
$welcomeLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$welcomeLabel.ForeColor = $lightText
$welcomeLabel.AutoSize  = $true
$welcomeLabel.Location  = New-Object System.Drawing.Point(20, 20)
$welcomeCard.Controls.Add($welcomeLabel)

# Description Label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text      = "Browse and download folders from your GitHub repository"
$descLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 11)
$descLabel.ForeColor = $secondaryText
$descLabel.AutoSize  = $true
$descLabel.Location  = New-Object System.Drawing.Point(20, 60)
$welcomeCard.Controls.Add($descLabel)

# Folder List Card
$listCard = New-Object System.Windows.Forms.Panel
$listCard.Dock = 'Fill'
$listCard.BackColor = $cardBackground
$listCard.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 20)
$mainLayout.Controls.Add($listCard, 0, 2)

# List Title
$listTitle = New-Object System.Windows.Forms.Label
$listTitle.Text      = "Repository Folders"
$listTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$listTitle.ForeColor = $lightText
$listTitle.AutoSize  = $true
$listTitle.Location  = New-Object System.Drawing.Point(20, 15)
$listCard.Controls.Add($listTitle)

# Folder ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View       = 'Details'
$listView.Size       = New-Object System.Drawing.Size(770, 300)
$listView.Location   = New-Object System.Drawing.Point(20, 50)
$listView.FullRowSelect = $true
$listView.MultiSelect   = $true
$listView.BackColor     = $darkBackground
$listView.ForeColor     = $lightText
$listView.Font          = New-Object System.Drawing.Font("Segoe UI", 11)
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

$listView.Columns.Add("Folders", 750) | Out-Null
$listCard.Controls.Add($listView)

# Button Container
$buttonContainer = New-Object System.Windows.Forms.Panel
$buttonContainer.Dock = 'Fill'
$buttonContainer.BackColor = $darkBackground
$buttonContainer.Height = 80
$mainLayout.Controls.Add($buttonContainer, 0, 3)

# Button Layout
$buttonLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonLayout.Dock = 'Fill'
$buttonLayout.FlowDirection = 'LeftToRight'
$buttonLayout.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 10)
$buttonContainer.Controls.Add($buttonLayout)

# Download Button
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text       = 'Download Selected'
$btnDownload.Size       = New-Object System.Drawing.Size(300, 50)
$btnDownload.BackColor  = $primaryBlue
$btnDownload.ForeColor  = $lightText
$btnDownload.Enabled    = $false
$btnDownload.FlatStyle  = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnDownload.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnDownload)

# Add spacer
$spacer = New-Object System.Windows.Forms.Panel
$spacer.Size = New-Object System.Drawing.Size(20, 10)
$buttonLayout.Controls.Add($spacer)

# Refresh Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text       = 'Refresh List'
$btnRefresh.Size       = New-Object System.Drawing.Size(180, 50)
$btnRefresh.BackColor  = $buttonBackground
$btnRefresh.ForeColor  = $lightText
$btnRefresh.FlatStyle  = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnRefresh)

# Status Container
$statusContainer = New-Object System.Windows.Forms.Panel
$statusContainer.Dock = 'Bottom'
$statusContainer.Height = 40
$statusContainer.BackColor = $darkBackground
$form.Controls.Add($statusContainer)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = 'Top'
$progressBar.Height = 6
$progressBar.Style = 'Marquee'
$progressBar.Visible = $false
$progressBar.ForeColor = $progressBlue
$statusContainer.Controls.Add($progressBar)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Dock = 'Fill'
$statusLabel.Text = "Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.ForeColor = $secondaryText
$statusLabel.TextAlign = 'MiddleLeft'
$statusLabel.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 0)
$statusContainer.Controls.Add($statusLabel)

# Populate folder list
$loadFolders = {
    try {
        $statusLabel.Text = "Connecting to GitHub..."
        $progressBar.Visible = $true
        $progressBar.Style = 'Marquee'
        $form.Refresh()
        
        $content = Get-GitHubContent
        $dirs = $content | Where-Object { $_.type -eq 'dir' } | Sort-Object name
        
        if (-not $dirs) {
            $statusLabel.Text = "No folders found in repository"
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
            $item.ForeColor = $lightText
            $listView.Items.Add($item) | Out-Null
        }
        $listView.EndUpdate()
        $statusLabel.Text = "$($dirs.Count) folders found - Select folders to download"
        $btnDownload.Enabled = $true
    } catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "GitHub API Error:`n$($_.Exception.Message)",
            'Connection Failed',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
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
        ) | Out-Null
        return
    }

    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select download location"
    $dlg.RootFolder = 'MyComputer'
    $dlg.ShowNewFolderButton = $true
    
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
        $statusLabel.Text = "Download canceled"
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
        $statusLabel.Text = "Preparing download..."
        $form.Refresh()
        
        # First pass: Count total files
        foreach ($item in $foldersToDownload) {
            $path = $item.Tag
            $files = Get-GitHubFileList -Path $path -ProgressBar $progressBar -StatusLabel $statusLabel
            $totalFiles += $files.Count
        }
        
        if ($totalFiles -eq 0) {
            $statusLabel.Text = "No files found in selected folders"
            return
        }
        
        $progressBar.Maximum = $totalFiles
        $progressBar.Value = 0
        $counter = 0
        
        # Second pass: Download files
        foreach ($item in $foldersToDownload) {
            $folder = $item.Text
            $path = $item.Tag
            $statusLabel.Text = "Processing folder: $folder"
            $form.Refresh()
            
            $files = Get-GitHubFileList -Path $path -ProgressBar $null -StatusLabel $statusLabel
            
            foreach ($file in $files) {
                $counter++
                $progressBar.Value = $counter
                $statusLabel.Text = "Downloading file $counter/$totalFiles - $($file.RelativePath)"
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
                    $statusLabel.Text = "Error downloading $($file.RelativePath): $($_.Exception.Message)"
                }
            }
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Successfully downloaded $successCount/$totalFiles files to:`n$($dlg.SelectedPath)",
            'Download Complete',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        $statusLabel.Text = "Download completed: $successCount files"
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Download failed:`n$($_.Exception.Message)",
            'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        $statusLabel.Text = "Download failed: $($_.Exception.Message)"
    } finally {
        $progressBar.Visible = $false
        $btnDownload.Enabled = $true
        $listView.Enabled = $true
    }
})

# Refresh button handler
$btnRefresh.Add_Click({
    $btnDownload.Enabled = $false
    $statusLabel.Text = "Refreshing folder list..."
    & $loadFolders
})

# Load folders after form shows
$form.Add_Shown({
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $statusLabel.Text = "Loading repository content..."
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
        ) | Out-Null
        $_.Cancel = $true
    }
})

# Add hover effects to buttons
$buttonHover = {
    $button = $sender
    $button.BackColor = $hoverBlue
    $button.ForeColor = $darkBackground
}

$buttonLeave = {
    $button = $sender
    if ($button.Text -eq 'Download Selected') {
        $button.BackColor = $primaryBlue
    } else {
        $button.BackColor = $buttonBackground
    }
    $button.ForeColor = $lightText
}

$btnDownload.Add_MouseEnter($buttonHover)
$btnDownload.Add_MouseLeave($buttonLeave)
$btnRefresh.Add_MouseEnter($buttonHover)
$btnRefresh.Add_MouseLeave($buttonLeave)

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
