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

# Global variables for SQL credentials
$global:SqlCredentials = $null

function Get-GitHubContent ($Path = '') {
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/contents"
    
    if ($Path) {
        $apiUrl += "/$([uri]::EscapeDataString($Path))"
    }
    
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

function Get-SqlFilesInFolder ($FolderPath) {
    $items = Get-GitHubContent -Path $FolderPath
    $sqlFiles = @()
    
    foreach ($item in $items) {
        if ($item.type -eq 'file' -and $item.name -like '*.sql') {
            $sqlFiles += [PSCustomObject]@{
                Name = $item.name
                Path = $item.path
                DownloadUrl = $item.download_url
            }
        }
    }
    
    return $sqlFiles | Sort-Object Name
}

function Invoke-SqlScript {
    param(
        [string]$ScriptContent,
        [string]$Server,
        [string]$Database,
        [string]$Username,
        [string]$Password
    )
    
    try {
        # Create SQL connection
        $connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        # Split script by GO commands
        $batches = $ScriptContent -split "\bGO\b"
        
        foreach ($batch in $batches) {
            if (-not [string]::IsNullOrWhiteSpace($batch)) {
                $command = $connection.CreateCommand()
                $command.CommandText = $batch
                $command.ExecuteNonQuery() | Out-Null
            }
        }
        
        return $true
    } catch {
        return $false
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# GUI Setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Modern color palette
$darkBackground   = '#0f172a'     # Deep navy background
$cardBackground   = '#1e293b'     # Card background
$primaryBlue      = '#3b82f6'     # Vibrant blue
$lightText        = '#f1f5f9'     # Soft white text
$secondaryText    = '#94a3b8'     # Grayish-blue text
$progressBlue     = '#60a5fa'     # Light blue for progress
$buttonBackground = '#334155'     # Button background
$hoverBlue        = '#93c5fd'     # Light blue for hover
$successGreen     = '#10b981'     # Success green
$errorRed         = '#ef4444'     # Error red

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text            = "SQL Script Runner"
$form.Size            = '900,700'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $darkBackground
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.Padding         = New-Object System.Windows.Forms.Padding(20)

# Main Layout Panel
$mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$mainLayout.Dock = 'Fill'
$mainLayout.ColumnCount = 1
$mainLayout.RowCount = 3
$mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$form.Controls.Add($mainLayout)

# Header Panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = 'Fill'
$headerPanel.BackColor = $darkBackground
$headerPanel.Height = 90
$mainLayout.Controls.Add($headerPanel, 0, 0)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "SQL Script Runner"
$titleLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $lightText
$titleLabel.AutoSize  = $true
$titleLabel.Location  = New-Object System.Drawing.Point(20, 20)
$headerPanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$repoLabel.ForeColor = $secondaryText
$repoLabel.AutoSize  = $true
$repoLabel.Location  = New-Object System.Drawing.Point(20, 60)
$headerPanel.Controls.Add($repoLabel)

# Credentials Button
$btnCredentials = New-Object System.Windows.Forms.Button
$btnCredentials.Text       = 'SET CREDENTIALS'
$btnCredentials.Size       = New-Object System.Drawing.Size(150, 35)
$btnCredentials.BackColor  = $buttonBackground
$btnCredentials.ForeColor  = $lightText
$btnCredentials.FlatStyle  = 'Flat'
$btnCredentials.FlatAppearance.BorderSize = 0
$btnCredentials.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnCredentials.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCredentials.Location  = New-Object System.Drawing.Point(700, 25)
$headerPanel.Controls.Add($btnCredentials)

# Credentials Status
$credentialsStatus = New-Object System.Windows.Forms.Label
$credentialsStatus.Text      = "Credentials: Not Set"
$credentialsStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$credentialsStatus.ForeColor = $errorRed
$credentialsStatus.AutoSize  = $true
$credentialsStatus.Location  = New-Object System.Drawing.Point(700, 65)
$headerPanel.Controls.Add($credentialsStatus)

# Split Container
$splitContainer = New-Object System.Windows.Forms.SplitContainer
$splitContainer.Dock = 'Fill'
$splitContainer.Orientation = 'Horizontal'
$splitContainer.SplitterDistance = 250
$splitContainer.BackColor = $darkBackground
$splitContainer.Panel1.BackColor = $cardBackground
$splitContainer.Panel2.BackColor = $cardBackground
$mainLayout.Controls.Add($splitContainer, 0, 1)

# Folders Panel
$foldersPanel = New-Object System.Windows.Forms.Panel
$foldersPanel.Dock = 'Fill'
$foldersPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$splitContainer.Panel1.Controls.Add($foldersPanel)

# Folders Title
$foldersTitle = New-Object System.Windows.Forms.Label
$foldersTitle.Text      = "SCRIPT CATEGORIES"
$foldersTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$foldersTitle.ForeColor = $secondaryText
$foldersTitle.AutoSize  = $true
$foldersTitle.Location  = New-Object System.Drawing.Point(10, 10)
$foldersPanel.Controls.Add($foldersTitle)

# Folders ListView
$foldersListView = New-Object System.Windows.Forms.ListView
$foldersListView.View       = 'Details'
$foldersListView.Location   = New-Object System.Drawing.Point(10, 40)
$foldersListView.Size       = New-Object System.Drawing.Size(800, 180)
$foldersListView.FullRowSelect = $true
$foldersListView.MultiSelect   = $false
$foldersListView.BackColor     = $darkBackground
$foldersListView.ForeColor     = $lightText
$foldersListView.BorderStyle   = 'FixedSingle'
$foldersListView.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$foldersListView.HeaderStyle   = 'None'

# Add folder icon
try {
    $foldersListView.SmallImageList = New-Object System.Windows.Forms.ImageList
    $foldersListView.SmallImageList.ImageSize = New-Object System.Drawing.Size(24, 24)
    $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
    $foldersListView.SmallImageList.Images.Add($folderIcon)
} catch {
    # Continue without icons if extraction fails
}

$foldersListView.Columns.Add("Folders", 780) | Out-Null
$foldersPanel.Controls.Add($foldersListView)

# Files Panel
$filesPanel = New-Object System.Windows.Forms.Panel
$filesPanel.Dock = 'Fill'
$filesPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$splitContainer.Panel2.Controls.Add($filesPanel)

# Files Title
$filesTitle = New-Object System.Windows.Forms.Label
$filesTitle.Text      = "SQL SCRIPTS"
$filesTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$filesTitle.ForeColor = $secondaryText
$filesTitle.AutoSize  = $true
$filesTitle.Location  = New-Object System.Drawing.Point(10, 10)
$filesPanel.Controls.Add($filesTitle)

# Files ListView
$filesListView = New-Object System.Windows.Forms.ListView
$filesListView.View       = 'Details'
$filesListView.Location   = New-Object System.Drawing.Point(10, 40)
$filesListView.Size       = New-Object System.Drawing.Size(800, 300)
$filesListView.FullRowSelect = $true
$filesListView.MultiSelect   = $false
$filesListView.BackColor     = $darkBackground
$filesListView.ForeColor     = $lightText
$filesListView.BorderStyle   = 'FixedSingle'
$filesListView.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$filesListView.HeaderStyle   = 'None'
$filesListView.Columns.Add("Scripts", 780) | Out-Null
$filesPanel.Controls.Add($filesListView)

# Button Container
$buttonContainer = New-Object System.Windows.Forms.Panel
$buttonContainer.Dock = 'Fill'
$buttonContainer.BackColor = $darkBackground
$buttonContainer.Height = 70
$mainLayout.Controls.Add($buttonContainer, 0, 2)

# Button Layout
$buttonLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonLayout.Dock = 'Fill'
$buttonLayout.FlowDirection = 'RightToLeft'
$buttonLayout.Padding = New-Object System.Windows.Forms.Padding(0, 10, 20, 10)
$buttonContainer.Controls.Add($buttonLayout)

# Run Button
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text       = 'RUN SCRIPT'
$btnRun.Size       = New-Object System.Drawing.Size(150, 45)
$btnRun.BackColor  = $successGreen
$btnRun.ForeColor  = $lightText
$btnRun.Enabled    = $false
$btnRun.FlatStyle  = 'Flat'
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnRun)

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Dock = 'Bottom'
$statusBar.BackColor = $darkBackground
$statusBar.ForeColor = $secondaryText
$statusBar.SizingGrip = $false
$statusBar.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($statusBar)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.ForeColor = $secondaryText
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.AutoSize = $true
$statusBar.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = 'Bottom'
$progressBar.Height = 6
$progressBar.Style = 'Marquee'
$progressBar.Visible = $false
$progressBar.ForeColor = $progressBlue
$form.Controls.Add($progressBar)

# Function to show credentials form
function Show-CredentialsForm {
    $credentialsForm = New-Object System.Windows.Forms.Form
    $credentialsForm.Text = "Database Credentials"
    $credentialsForm.Size = '400, 300'
    $credentialsForm.StartPosition = 'CenterScreen'
    $credentialsForm.FormBorderStyle = 'FixedDialog'
    $credentialsForm.BackColor = $darkBackground
    $credentialsForm.Padding = New-Object System.Windows.Forms.Padding(20)
    
    $tableLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $tableLayout.Dock = 'Fill'
    $tableLayout.ColumnCount = 2
    $tableLayout.RowCount = 5
    $tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null
    $tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70))) | Out-Null
    $credentialsForm.Controls.Add($tableLayout)
    
    # Server
    $lblServer = New-Object System.Windows.Forms.Label
    $lblServer.Text = "Server:"
    $lblServer.ForeColor = $lightText
    $lblServer.Dock = 'Fill'
    $lblServer.TextAlign = 'MiddleRight'
    $tableLayout.Controls.Add($lblServer, 0, 0)
    
    $txtServer = New-Object System.Windows.Forms.TextBox
    $txtServer.Dock = 'Fill'
    $txtServer.BackColor = $darkBackground
    $txtServer.ForeColor = $lightText
    $txtServer.BorderStyle = 'FixedSingle'
    $tableLayout.Controls.Add($txtServer, 1, 0)
    
    # Database
    $lblDatabase = New-Object System.Windows.Forms.Label
    $lblDatabase.Text = "Database:"
    $lblDatabase.ForeColor = $lightText
    $lblDatabase.Dock = 'Fill'
    $lblDatabase.TextAlign = 'MiddleRight'
    $tableLayout.Controls.Add($lblDatabase, 0, 1)
    
    $txtDatabase = New-Object System.Windows.Forms.TextBox
    $txtDatabase.Dock = 'Fill'
    $txtDatabase.BackColor = $darkBackground
    $txtDatabase.ForeColor = $lightText
    $txtDatabase.BorderStyle = 'FixedSingle'
    $tableLayout.Controls.Add($txtDatabase, 1, 1)
    
    # Username
    $lblUsername = New-Object System.Windows.Forms.Label
    $lblUsername.Text = "Username:"
    $lblUsername.ForeColor = $lightText
    $lblUsername.Dock = 'Fill'
    $lblUsername.TextAlign = 'MiddleRight'
    $tableLayout.Controls.Add($lblUsername, 0, 2)
    
    $txtUsername = New-Object System.Windows.Forms.TextBox
    $txtUsername.Dock = 'Fill'
    $txtUsername.BackColor = $darkBackground
    $txtUsername.ForeColor = $lightText
    $txtUsername.BorderStyle = 'FixedSingle'
    $tableLayout.Controls.Add($txtUsername, 1, 2)
    
    # Password
    $lblPassword = New-Object System.Windows.Forms.Label
    $lblPassword.Text = "Password:"
    $lblPassword.ForeColor = $lightText
    $lblPassword.Dock = 'Fill'
    $lblPassword.TextAlign = 'MiddleRight'
    $tableLayout.Controls.Add($lblPassword, 0, 3)
    
    $txtPassword = New-Object System.Windows.Forms.TextBox
    $txtPassword.Dock = 'Fill'
    $txtPassword.BackColor = $darkBackground
    $txtPassword.ForeColor = $lightText
    $txtPassword.BorderStyle = 'FixedSingle'
    $txtPassword.PasswordChar = '*'
    $tableLayout.Controls.Add($txtPassword, 1, 3)
    
    # Buttons
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Dock = 'Fill'
    $buttonPanel.Height = 40
    $tableLayout.Controls.Add($buttonPanel, 0, 4)
    $tableLayout.SetColumnSpan($buttonPanel, 2)
    
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "SAVE"
    $btnSave.Size = New-Object System.Drawing.Size(100, 30)
    $btnSave.BackColor = $primaryBlue
    $btnSave.ForeColor = $lightText
    $btnSave.FlatStyle = 'Flat'
    $btnSave.FlatAppearance.BorderSize = 0
    $btnSave.Location = New-Object System.Drawing.Point(150, 5)
    $btnSave.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $buttonPanel.Controls.Add($btnSave)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "CANCEL"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.BackColor = $buttonBackground
    $btnCancel.ForeColor = $lightText
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 0
    $btnCancel.Location = New-Object System.Drawing.Point(260, 5)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $buttonPanel.Controls.Add($btnCancel)
    
    $credentialsForm.AcceptButton = $btnSave
    $credentialsForm.CancelButton = $btnCancel
    
    if ($credentialsForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            Server = $txtServer.Text
            Database = $txtDatabase.Text
            Username = $txtUsername.Text
            Password = $txtPassword.Text
        }
    }
    
    return $null
}

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
        
        $foldersListView.BeginUpdate()
        $foldersListView.Items.Clear()
        foreach ($dir in $dirs) {
            $item = New-Object System.Windows.Forms.ListViewItem($dir.name)
            $item.Tag = $dir.path
            if ($foldersListView.SmallImageList -ne $null) {
                $item.ImageIndex = 0
            }
            $item.ForeColor = $lightText
            $foldersListView.Items.Add($item) | Out-Null
        }
        $foldersListView.EndUpdate()
        $statusLabel.Text = "$($dirs.Count) folders found"
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

# Folder selection handler
$foldersListView.Add_ItemSelectionChanged({
    if ($_.IsSelected) {
        $selectedItem = $_.Item
        $folderPath = $selectedItem.Tag
        $statusLabel.Text = "Loading scripts for: $($selectedItem.Text)"
        
        try {
            $filesListView.BeginUpdate()
            $filesListView.Items.Clear()
            $btnRun.Enabled = $false
            
            $sqlFiles = Get-SqlFilesInFolder -FolderPath $folderPath
            
            if ($sqlFiles) {
                foreach ($file in $sqlFiles) {
                    $item = New-Object System.Windows.Forms.ListViewItem($file.Name)
                    $item.Tag = $file
                    $item.ForeColor = $lightText
                    $filesListView.Items.Add($item) | Out-Null
                }
                $btnRun.Enabled = $true
                $statusLabel.Text = "$($sqlFiles.Count) SQL scripts found"
            } else {
                $statusLabel.Text = "No SQL scripts found in this folder"
            }
        } catch {
            $statusLabel.Text = "Error: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show(
                "Error loading scripts:`n$($_.Exception.Message)",
                'Error',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        } finally {
            $filesListView.EndUpdate()
        }
    }
})

# Script selection handler
$filesListView.Add_ItemSelectionChanged({
    if ($_.IsSelected) {
        $btnRun.Enabled = $true
    }
})

# Run button handler
$btnRun.Add_Click({
    if ($filesListView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Please select a script to run',
            'Selection Required',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }
    
    # Get credentials if not already set
    if (-not $global:SqlCredentials) {
        $creds = Show-CredentialsForm
        if (-not $creds) {
            $statusLabel.Text = "Operation canceled - credentials not set"
            return
        }
        $global:SqlCredentials = $creds
        $credentialsStatus.Text = "Credentials: Set"
        $credentialsStatus.ForeColor = $successGreen
    }
    
    $selectedItem = $filesListView.SelectedItems[0]
    $fileInfo = $selectedItem.Tag
    $statusLabel.Text = "Running script: $($fileInfo.Name)"
    $progressBar.Visible = $true
    $progressBar.Style = 'Marquee'
    $form.Refresh()
    
    try {
        # Download script content
        $scriptContent = (Invoke-WebRequest -Uri $fileInfo.DownloadUrl -Headers $Headers -UserAgent "PowerShellApp").Content
        
        # Run SQL script
        $result = Invoke-SqlScript -ScriptContent $scriptContent `
            -Server $global:SqlCredentials.Server `
            -Database $global:SqlCredentials.Database `
            -Username $global:SqlCredentials.Username `
            -Password $global:SqlCredentials.Password
        
        if ($result) {
            $statusLabel.Text = "Script executed successfully: $($fileInfo.Name)"
            [System.Windows.Forms.MessageBox]::Show(
                "Script executed successfully!",
                'Success',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        } else {
            $statusLabel.Text = "Error executing script: $($fileInfo.Name)"
            [System.Windows.Forms.MessageBox]::Show(
                "Error executing script!",
                'Error',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    } catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Error running script:`n$($_.Exception.Message)",
            'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        $progressBar.Visible = $false
    }
})

# Credentials button handler
$btnCredentials.Add_Click({
    $creds = Show-CredentialsForm
    if ($creds) {
        $global:SqlCredentials = $creds
        $credentialsStatus.Text = "Credentials: Set"
        $credentialsStatus.ForeColor = $successGreen
        $statusLabel.Text = "Database credentials updated"
    } else {
        $statusLabel.Text = "Credentials update canceled"
    }
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

# Button hover effects
$btnRun.Add_MouseEnter({
    $btnRun.BackColor = $hoverBlue
})
$btnRun.Add_MouseLeave({
    $btnRun.BackColor = $successGreen
})
$btnCredentials.Add_MouseEnter({
    $btnCredentials.BackColor = $hoverBlue
})
$btnCredentials.Add_MouseLeave({
    $btnCredentials.BackColor = $buttonBackground
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
