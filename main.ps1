# CONFIG - Verify these details match your GitHub repository
$Owner = 'iamleoncio'
$Repo = 'mssql_query_updates'
$Branch = 'main'
$GitHubToken = '' # Optional: Add personal access token if needed
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

<#
.SYNOPSIS
    Retrieves content from a GitHub repository.

.DESCRIPTION
    This function connects to the GitHub API to fetch the contents of a specified
    path within the repository and branch configured globally.

.PARAMETER Path
    The specific path within the repository to retrieve content from.
    If not provided, it fetches the root content.

.RETURNS
    A PowerShell object representing the content of the specified path.
    Throws an exception on API errors.
#>
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

<#
.SYNOPSIS
    Retrieves SQL files from a specified GitHub folder path.

.DESCRIPTION
    This function uses Get-GitHubContent to list items in a folder and filters
    them to return only files ending with '.sql'.

.PARAMETER FolderPath
    The path to the folder in the GitHub repository.

.RETURNS
    An array of PSCustomObjects, each representing a SQL file with its name,
    path, and download URL.
#>
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

<#
.SYNOPSIS
    Executes a SQL script against a specified database.

.DESCRIPTION
    This function takes SQL script content, database connection details,
    and executes the script. It splits the script by 'GO' commands
    to handle multiple batches.

.PARAMETER ScriptContent
    The content of the SQL script to execute.

.PARAMETER Server
    The SQL Server instance name.

.PARAMETER Database
    The name of the database to connect to.

.PARAMETER Username
    The username for SQL authentication.

.PARAMETER Password
    The password for SQL authentication.

.RETURNS
    $true if the script executed successfully, $false otherwise.
#>
function Invoke-SqlScript {
    param(
        [string]$ScriptContent,
        [string]$Server,
        [string]$Database,
        [string]$Username,
        [string]$Password
    )

    $connection = $null
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
        # Log the specific SQL error for debugging, but return false to the caller
        Write-Error "SQL Execution Error: $($_.Exception.Message)"
        return $false
    } finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
            $connection.Dispose() # Dispose of the connection object
        }
    }
}

# GUI Setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Modern color palette
$darkBackground = '#0f172a'     # Deep navy background
$cardBackground = '#1e293b'     # Card background
$primaryBlue = '#3b82f6'     # Vibrant blue
$lightText = '#f1f5f9'     # Soft white text
$secondaryText = '#94a3b8'     # Grayish-blue text
$progressBlue = '#60a5fa'     # Light blue for progress
$buttonBackground = '#334155'     # Button background
$hoverBlue = '#93c5fd'     # Light blue for hover
$successGreen = '#10b981'     # Success green
$errorRed = '#ef4444'     # Error red
$selectionColor = '#1e3a8a'     # Selection highlight blue (darker primary blue)
$highlightColor = '#3b82f633'   # Light blue highlight for SQL files (more transparent)

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Script Runner"
$form.Size = '900,700'
$form.MinimumSize = '800,600' # Set a minimum size to prevent too small resizing
$form.StartPosition = 'CenterScreen'
$form.BackColor = $darkBackground
$form.FormBorderStyle = 'Sizable' # Allow resizing
$form.MaximizeBox = $true # Allow maximizing
$form.Padding = New-Object System.Windows.Forms.Padding(20)

# Main Layout Panel
$mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$mainLayout.Dock = 'Fill'
$mainLayout.ColumnCount = 1
$mainLayout.RowCount = 3
$mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 90))) | Out-Null # Fixed height for header
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 70))) | Out-Null # Fixed height for buttons
$form.Controls.Add($mainLayout)

# Header Panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = 'Fill'
$headerPanel.BackColor = $darkBackground
# $headerPanel.Height is set by RowStyle
$mainLayout.Controls.Add($headerPanel, 0, 0)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "SQL Script Runner"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $lightText
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$headerPanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text = "$Owner/$Repo : $Branch"
$repoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$repoLabel.ForeColor = $secondaryText
$repoLabel.AutoSize = $true
$repoLabel.Location = New-Object System.Drawing.Point(20, 60)
$headerPanel.Controls.Add($repoLabel)

# Credentials Button
$btnCredentials = New-Object System.Windows.Forms.Button
$btnCredentials.Text = 'SET CREDENTIALS'
$btnCredentials.Size = New-Object System.Drawing.Size(150, 35)
$btnCredentials.BackColor = $buttonBackground
$btnCredentials.ForeColor = $lightText
$btnCredentials.FlatStyle = 'Flat'
$btnCredentials.FlatAppearance.BorderSize = 0
$btnCredentials.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnCredentials.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCredentials.Anchor = 'Top, Right' # Anchor to top-right
$btnCredentials.Location = New-Object System.Drawing.Point($headerPanel.Width - $btnCredentials.Width - 20, 25) # Initial position
$headerPanel.Controls.Add($btnCredentials)

# Credentials Status
$credentialsStatus = New-Object System.Windows.Forms.Label
$credentialsStatus.Text = "Credentials: Not Set"
$credentialsStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$credentialsStatus.ForeColor = $errorRed
$credentialsStatus.AutoSize = $true
$credentialsStatus.Anchor = 'Top, Right' # Anchor to top-right
$credentialsStatus.Location = New-Object System.Drawing.Point($headerPanel.Width - $credentialsStatus.Width - 20, 65) # Initial position
$headerPanel.Controls.Add($credentialsStatus)

# Handle header panel resize to reposition buttons/labels
$headerPanel.Add_Resize({
    $btnCredentials.Location = New-Object System.Drawing.Point($headerPanel.Width - $btnCredentials.Width - 20, 25)
    $credentialsStatus.Location = New-Object System.Drawing.Point($headerPanel.Width - $credentialsStatus.Width - 20, 65)
})

# Scripts Panel
$scriptsPanel = New-Object System.Windows.Forms.Panel
$scriptsPanel.Dock = 'Fill'
$scriptsPanel.BackColor = $cardBackground
$scriptsPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$mainLayout.Controls.Add($scriptsPanel, 0, 1)

# TreeView for Scripts
$treeView = New-Object System.Windows.Forms.TreeView
$treeView.Dock = 'Fill'
$treeView.CheckBoxes = $true
$treeView.BackColor = $darkBackground
$treeView.ForeColor = $lightText
$treeView.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$treeView.BorderStyle = 'FixedSingle'
$treeView.FullRowSelect = $true
$treeView.HideSelection = $false
$treeView.ShowLines = $false
$treeView.ShowPlusMinus = $false # We'll manage expansion visuals
$treeView.ShowRootLines = $false
$treeView.DrawMode = 'OwnerDrawText'
$scriptsPanel.Controls.Add($treeView)

# Custom drawing for TreeView nodes (checkboxes, icons, and text)
$treeView.Add_DrawNode({
    param($sender, $e)

    $e.DrawDefault = $false # We are drawing everything ourselves

    # Define spacing and sizes
    $checkBoxSize = 16
    $iconSize = 24
    $spacing = 5 # Space between elements (checkbox, icon, text)

    # Calculate starting X position based on node level
    $leftPadding = 10 # Base padding for the tree view
    $indent = 20 # Indent for each level
    $x = $e.Bounds.Left + $leftPadding + ($e.Node.Level * $indent)

    # Draw background
    # Background for folders and selected items can be different
    $bgBrush = New-Object System.Drawing.SolidBrush $darkBackground
    if (($e.State -band [System.Windows.Forms.TreeNodeStates]::Selected) -ne 0) {
        $bgBrush = New-Object System.Drawing.SolidBrush $selectionColor
    } elseif ($e.Node.ImageKey -eq "Folder") {
        # Use cardBackground for folder rows for better visual separation
        $bgBrush = New-Object System.Drawing.SolidBrush $cardBackground
    }
    $e.Graphics.FillRectangle($bgBrush, $e.Bounds)


    # Draw checkbox
    $checkBoxRect = New-Object System.Drawing.Rectangle(
        $x,
        $e.Bounds.Top + ($e.Bounds.Height - $checkBoxSize) / 2, # Center vertically
        $checkBoxSize,
        $checkBoxSize
    )
    $state = if ($e.Node.Checked) {
        [System.Windows.Forms.VisualStyles.CheckBoxState]::CheckedNormal
    } else {
        [System.Windows.Forms.VisualStyles.CheckBoxState]::UncheckedNormal
    }
    [System.Windows.Forms.CheckBoxRenderer]::DrawCheckBox($e.Graphics, $checkBoxRect.Location, $state)

    $x += $checkBoxSize + $spacing

    # Draw icon if available
    if ($treeView.ImageList -ne $null -and $e.Node.ImageKey -ne $null) {
        $image = $treeView.ImageList.Images[$e.Node.ImageKey]
        if ($image -ne $null) {
            $iconY = $e.Bounds.Top + ($e.Bounds.Height - $iconSize) / 2 # Center vertically
            $e.Graphics.DrawImage($image, $x, $iconY, $iconSize, $iconSize)
            $x += $iconSize + $spacing
        }
    }

    # Draw text
    $textY = $e.Bounds.Top + ($e.Bounds.Height - $treeView.Font.Height) / 2 # Center vertically
    $textBrush = New-Object System.Drawing.SolidBrush $lightText
    $e.Graphics.DrawString($e.Node.Text, $treeView.Font, $textBrush, $x, $textY)

    # Draw default text for other states (e.g., focused) if needed, though usually handled by DrawDefault
    # For fully custom drawing, ensure all states are handled.
})

# Add icons
try {
    $imageList = New-Object System.Windows.Forms.ImageList
    $imageList.ImageSize = New-Object System.Drawing.Size(24, 24)

    # Folder icon (using system icon)
    $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll").ToBitmap()
    $imageList.Images.Add("Folder", $folderIcon) | Out-Null

    # SQL file icon (using a generic document icon as substitute, adjust as needed)
    $fileIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\System32\imageres.dll", 100).ToBitmap() # Icon index for a common document icon
    $imageList.Images.Add("SQL", $fileIcon) | Out-Null

    $treeView.ImageList = $imageList
} catch {
    Write-Warning "Could not load system icons. TreeView will display without icons. Error: $($_.Exception.Message)"
    # Continue without icons if extraction fails
}

# Button Container
$buttonContainer = New-Object System.Windows.Forms.Panel
$buttonContainer.Dock = 'Fill'
$buttonContainer.BackColor = $darkBackground
# $buttonContainer.Height is set by RowStyle
$mainLayout.Controls.Add($buttonContainer, 0, 2)

# Button Layout (FlowLayoutPanel for flexible button positioning)
$buttonLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonLayout.Dock = 'Fill'
$buttonLayout.FlowDirection = 'RightToLeft'
$buttonLayout.Padding = New-Object System.Windows.Forms.Padding(0, 10, 20, 10) # Padding for buttons
$buttonLayout.WrapContents = $false # Prevent buttons from wrapping
$buttonLayout.Controls.Add($btnRun) # Add run button first for right-to-left flow
$buttonLayout.Controls.Add($btnRefresh) # Then refresh button
$buttonContainer.Controls.Add($buttonLayout)

# Run Button
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = 'RUN SELECTED SCRIPTS'
$btnRun.Size = New-Object System.Drawing.Size(220, 45)
$btnRun.BackColor = $successGreen
$btnRun.ForeColor = $lightText
$btnRun.Enabled = $false # Disabled by default
$btnRun.FlatStyle = 'Flat'
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand

# Refresh Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = 'REFRESH'
$btnRefresh.Size = New-Object System.Drawing.Size(120, 45)
$btnRefresh.BackColor = $buttonBackground
$btnRefresh.ForeColor = $lightText
$btnRefresh.FlatStyle = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand

# Status Bar Panel (to contain label and progress bar)
$statusBarPanel = New-Object System.Windows.Forms.Panel
$statusBarPanel.Dock = 'Bottom'
$statusBarPanel.Height = 30 # Adjust height as needed
$statusBarPanel.BackColor = $darkBackground
$form.Controls.Add($statusBarPanel)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.ForeColor = $secondaryText
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.AutoSize = $false # Set to false to allow docking
$statusLabel.Dock = 'Fill' # Fill the status bar panel
$statusLabel.TextAlign = 'MiddleLeft' # Align text to the middle left
$statusLabel.Padding = New-Object System.Windows.Forms.Padding(10,0,0,0) # Add left padding
$statusBarPanel.Controls.Add($statusLabel)

# Progress Bar (overlayed/positioned within the status bar panel for cleaner look)
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = 'Bottom' # Dock to bottom of status bar panel
$progressBar.Height = 6 # Make it thin
$progressBar.Style = 'Marquee'
$progressBar.Visible = $false
$progressBar.ForeColor = $progressBlue
$progressBar.BackColor = $cardBackground # Set a background for the bar
$statusBarPanel.Controls.Add($progressBar)
$progressBar.BringToFront() # Ensure progress bar is on top of the status label

<#
.SYNOPSIS
    Displays a form to collect database credentials.

.DESCRIPTION
    This function creates and displays a modal Windows Form that prompts the user
    for SQL Server, Database, Username, and Password.

.RETURNS
    A hash table containing the entered credentials if the user clicks 'SAVE',
    otherwise $null.
#>
function Show-CredentialsForm {
    $credentialsForm = New-Object System.Windows.Forms.Form
    $credentialsForm.Text = "Database Credentials"
    $credentialsForm.Size = '400, 300'
    $credentialsForm.StartPosition = 'CenterScreen'
    $credentialsForm.FormBorderStyle = 'FixedDialog'
    $credentialsForm.BackColor = $darkBackground
    $credentialsForm.Padding = New-Object System.Windows.Forms.Padding(20)
    $credentialsForm.MinimizeBox = $false
    $credentialsForm.MaximizeBox = $false

    $tableLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $tableLayout.Dock = 'Fill'
    $tableLayout.ColumnCount = 2
    $tableLayout.RowCount = 5
    $tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null
    $tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70))) | Out-Null
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null # Server
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null # Database
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null # Username
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null # Password
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null # Buttons (take remaining space)
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
    $txtServer.BackColor = $cardBackground # Use card background for textboxes
    $txtServer.ForeColor = $lightText
    $txtServer.BorderStyle = 'FixedSingle'
    $txtServer.Margin = New-Object System.Windows.Forms.Padding(5, 5, 5, 5) # Add margin
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
    $txtDatabase.BackColor = $cardBackground
    $txtDatabase.ForeColor = $lightText
    $txtDatabase.BorderStyle = 'FixedSingle'
    $txtDatabase.Margin = New-Object System.Windows.Forms.Padding(5, 5, 5, 5)
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
    $txtUsername.BackColor = $cardBackground
    $txtUsername.ForeColor = $lightText
    $txtUsername.BorderStyle = 'FixedSingle'
    $txtUsername.Margin = New-Object System.Windows.Forms.Padding(5, 5, 5, 5)
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
    $txtPassword.BackColor = $cardBackground
    $txtPassword.ForeColor = $lightText
    $txtPassword.BorderStyle = 'FixedSingle'
    $txtPassword.PasswordChar = '*'
    $txtPassword.Margin = New-Object System.Windows.Forms.Padding(5, 5, 5, 5)
    $tableLayout.Controls.Add($txtPassword, 1, 3)

    # Buttons Panel (using FlowLayoutPanel for easy alignment)
    $buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttonPanel.Dock = 'Right' # Align buttons to the right
    $buttonPanel.FlowDirection = 'RightToLeft'
    $buttonPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 0) # Top padding
    $tableLayout.Controls.Add($buttonPanel, 0, 4)
    $tableLayout.SetColumnSpan($buttonPanel, 2) # Span both columns

    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "SAVE"
    $btnSave.Size = New-Object System.Drawing.Size(100, 30)
    $btnSave.BackColor = $primaryBlue
    $btnSave.ForeColor = $lightText
    $btnSave.FlatStyle = 'Flat'
    $btnSave.FlatAppearance.BorderSize = 0
    $btnSave.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnSave.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnSave.DialogResult = [System.Windows.Forms.DialogResult]::OK # Set DialogResult
    $buttonPanel.Controls.Add($btnSave)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "CANCEL"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.BackColor = $buttonBackground
    $btnCancel.ForeColor = $lightText
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 0
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $btnCancel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel # Set DialogResult
    $buttonPanel.Controls.Add($btnCancel)

    $credentialsForm.AcceptButton = $btnSave
    $credentialsForm.CancelButton = $btnCancel

    # Populate fields if credentials already exist
    if ($global:SqlCredentials) {
        $txtServer.Text = $global:SqlCredentials.Server
        $txtDatabase.Text = $global:SqlCredentials.Database
        $txtUsername.Text = $global:SqlCredentials.Username
        $txtPassword.Text = $global:SqlCredentials.Password
    }

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

<#
.SYNOPSIS
    Populates the TreeView with GitHub repository folders.

.DESCRIPTION
    This function fetches the root level directories from the configured GitHub
    repository and adds them as nodes to the TreeView. It uses lazy loading
    by adding a dummy node to each folder.
#>
function Populate-TreeView {
    $statusLabel.Text = "Loading repository folders..."
    $progressBar.Visible = $true
    $progressBar.Style = 'Marquee'
    $form.Refresh() # Force UI update

    try {
        $treeView.Nodes.Clear()
        $content = Get-GitHubContent

        # Add folders to tree view
        foreach ($item in $content) {
            if ($item.type -eq 'dir') {
                $folderNode = New-Object System.Windows.Forms.TreeNode($item.name)
                $folderNode.Tag = $item.path # Store GitHub path for later use
                $folderNode.ImageKey = "Folder"
                $folderNode.SelectedImageKey = "Folder"

                # Add dummy node to enable expansion arrow for lazy loading
                $dummyNode = New-Object System.Windows.Forms.TreeNode("Loading scripts...")
                $dummyNode.ForeColor = $secondaryText
                $folderNode.Nodes.Add($dummyNode) | Out-Null

                $treeView.Nodes.Add($folderNode) | Out-Null
            }
        }

        $statusLabel.Text = "Repository loaded. Found $($treeView.Nodes.Count) folders."
        $btnRun.Enabled = $false # Disable run button until a script is selected
    } catch {
        $statusLabel.Text = "Error: Failed to load repository content."
        [System.Windows.Forms.MessageBox]::Show(
            "GitHub API Error: `n$($_.Exception.Message)",
            'Connection Failed',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        $progressBar.Visible = $false
    }
}

# TreeView BeforeExpand event - Load scripts when folder is expanded
$treeView.Add_BeforeExpand({
    $node = $_.Node

    # Check if this node has the dummy "Loading..." child
    if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading scripts...") {
        $node.Nodes.Clear() # Remove the dummy node

        try {
            $statusLabel.Text = "Loading scripts for: $($node.Text)..."
            $progressBar.Visible = $true
            $progressBar.Style = 'Marquee'
            $form.Refresh()

            $sqlFiles = Get-SqlFilesInFolder -FolderPath $node.Tag

            foreach ($file in $sqlFiles) {
                $fileNode = New-Object System.Windows.Forms.TreeNode($file.Name)
                $fileNode.Tag = $file # Store the file object with Name, Path, DownloadUrl
                $fileNode.ImageKey = "SQL"
                $fileNode.SelectedImageKey = "SQL"
                $node.Nodes.Add($fileNode) | Out-Null
            }

            $statusLabel.Text = "Loaded $($sqlFiles.Count) scripts in $($node.Text)."
        } catch {
            $statusLabel.Text = "Error loading scripts for $($node.Text): $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show(
                "Error loading scripts for folder '$($node.Text)':`n$($_.Exception.Message)",
                'Error',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        } finally {
            $progressBar.Visible = $false
        }
    }
})

# TreeView AfterCheck event - Handle checkbox propagation
$treeView.Add_AfterCheck({
    param($sender, $e)

    $node = $e.Node
    # Only process if the change came from a user action (not programmatic)
    if ($e.Action -ne [System.Windows.Forms.TreeViewAction]::Unknown) {
        # If a folder node is checked/unchecked
        if ($node.ImageKey -eq "Folder") {
            $isChecked = $node.Checked

            # If folder hasn't been expanded yet, expand it to load children
            # This is crucial for propagating checks to lazily loaded nodes
            if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading scripts...") {
                # Temporarily suppress AfterCheck during programmatic expansion/loading
                # to prevent infinite loops or unexpected behavior.
                # This is a common pattern for TreeView programmatic updates.
                $treeView.BeginUpdate()
                try {
                    $node.Expand()
                    # Now that children are loaded, propagate the check state
                    foreach ($childNode in $node.Nodes) {
                        $childNode.Checked = $isChecked
                    }
                } finally {
                    $treeView.EndUpdate()
                }
            } else {
                # Propagate check state to existing children
                foreach ($childNode in $node.Nodes) {
                    $childNode.Checked = $isChecked
                }
            }
        }
        # If a child node is checked/unchecked, update parent's check state (partially checked)
        else { # Assumed to be a SQL file
            $parentNode = $node.Parent
            if ($parentNode -ne $null) {
                $checkedChildren = $parentNode.Nodes | Where-Object { $_.Checked }
                if ($checkedChildren.Count -eq $parentNode.Nodes.Count) {
                    $parentNode.Checked = $true
                } elseif ($checkedChildren.Count -eq 0) {
                    $parentNode.Checked = $false
                } else {
                    # This implies TriState functionality if we wanted partial checks
                    # For simplicity, we'll just check/uncheck the parent based on all children
                    # Or leave parent as is if only some are checked (more complex)
                    # For now, if any child is checked, the parent is checked. If none, parent unchecked.
                    $parentNode.Checked = ($checkedChildren.Count -gt 0)
                }
            }
        }
    }
    # Re-evaluate Run button state after any check change
    Update-RunButtonState
})


# Helper function to get all selected SQL files from tree (recursive)
function Get-SelectedSqlFilesRecursive ($nodes) {
    $selectedFiles = @()
    foreach ($node in $nodes) {
        if ($node.ImageKey -eq "SQL" -and $node.Checked) {
            $selectedFiles += $node.Tag # The file object (Name, Path, DownloadUrl)
        }
        # If it's a folder, and it's checked (meaning all its children should be processed)
        # or if we want to get checked files even if parent isn't fully checked, traverse
        elseif ($node.ImageKey -eq "Folder") {
            # Only recurse if the folder is expanded (children are loaded)
            if ($node.Nodes.Count -gt 0 -and $node.Nodes[0].Text -ne "Loading scripts...") {
                 $selectedFiles += Get-SelectedSqlFilesRecursive $node.Nodes
            }
        }
    }
    return $selectedFiles | Select-Object -Unique # Ensure no duplicates if logic overlaps
}

# Function to update the enabled state of the Run button
function Update-RunButtonState {
    $allSelectedFiles = Get-SelectedSqlFilesRecursive $treeView.Nodes
    $btnRun.Enabled = ($allSelectedFiles.Count -gt 0)
}

# TreeView AfterSelect event - Primarily for display, checkbox changes trigger button state
$treeView.Add_AfterSelect({
    # The run button state is now managed by AfterCheck to reflect multiple selections
    # This event is useful if you wanted to display details of the selected file.
})

<#
.SYNOPSIS
    Displays a modal form showing the results of script execution.

.DESCRIPTION
    This function creates a new form to summarize which scripts succeeded and
    which failed, listing them in separate sections.

.PARAMETER SuccessFiles
    An array of file names that were successfully executed.

.PARAMETER FailedFiles
    An array of file names that failed execution.
#>
function Show-ResultsForm ($successFiles, $failedFiles) {
    $resultsForm = New-Object System.Windows.Forms.Form
    $resultsForm.Text = "Execution Results"
    $resultsForm.Size = '600, 500'
    $resultsForm.MinimumSize = '500,400'
    $resultsForm.StartPosition = 'CenterParent'
    $resultsForm.FormBorderStyle = 'FixedDialog'
    $resultsForm.BackColor = $darkBackground
    $resultsForm.Padding = New-Object System.Windows.Forms.Padding(20)
    $resultsForm.MinimizeBox = $false
    $resultsForm.MaximizeBox = $false

    $tableLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $tableLayout.Dock = 'Fill'
    $tableLayout.ColumnCount = 1
    $tableLayout.RowCount = 4 # Added a row for the OK button
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null # Summary
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null # Success List
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null # Failed List
    $tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 50))) | Out-Null # OK Button
    $resultsForm.Controls.Add($tableLayout)

    # Summary
    $summaryLabel = New-Object System.Windows.Forms.Label
    $summaryLabel.Text = "Success: $($successFiles.Count) scripts, Failed: $($failedFiles.Count) scripts"
    $summaryLabel.ForeColor = $lightText
    $summaryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $summaryLabel.Dock = 'Fill'
    $summaryLabel.TextAlign = 'MiddleCenter'
    $summaryLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,10) # Add bottom margin
    $tableLayout.Controls.Add($summaryLabel, 0, 0)

    # Success Panel
    $successPanel = New-Object System.Windows.Forms.Panel
    $successPanel.Dock = 'Fill'
    $successPanel.BackColor = $cardBackground
    $successPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    $successPanel.BorderStyle = 'FixedSingle' # Add a border
    $successPanel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,10) # Add bottom margin
    $tableLayout.Controls.Add($successPanel, 0, 1)

    $successTitle = New-Object System.Windows.Forms.Label
    $successTitle.Text = "SUCCESSFUL SCRIPTS"
    $successTitle.ForeColor = $successGreen
    $successTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $successTitle.Dock = 'Top'
    $successPanel.Controls.Add($successTitle)

    $successList = New-Object System.Windows.Forms.ListBox
    $successList.Dock = 'Fill'
    $successList.BackColor = $darkBackground
    $successList.ForeColor = $successGreen
    $successList.BorderStyle = 'None'
    $successList.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $successList.Items.AddRange($successFiles)
    $successPanel.Controls.Add($successList)

    # Failed Panel
    $failedPanel = New-Object System.Windows.Forms.Panel
    $failedPanel.Dock = 'Fill'
    $failedPanel.BackColor = $cardBackground
    $failedPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    $failedPanel.BorderStyle = 'FixedSingle' # Add a border
    $tableLayout.Controls.Add($failedPanel, 0, 2)

    $failedTitle = New-Object System.Windows.Forms.Label
    $failedTitle.Text = "FAILED SCRIPTS"
    $failedTitle.ForeColor = $errorRed
    $failedTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $failedTitle.Dock = 'Top'
    $failedPanel.Controls.Add($failedTitle)

    $failedList = New-Object System.Windows.Forms.ListBox
    $failedList.Dock = 'Fill'
    $failedList.BackColor = $darkBackground
    $failedList.ForeColor = $errorRed
    $failedList.BorderStyle = 'None'
    $failedList.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $failedList.Items.AddRange($failedFiles)
    $failedPanel.Controls.Add($failedList)

    # OK Button Panel
    $okButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $okButtonPanel.Dock = 'Fill'
    $okButtonPanel.FlowDirection = 'RightToLeft'
    $okButtonPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)
    $tableLayout.Controls.Add($okButtonPanel, 0, 3)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Size = New-Object System.Drawing.Size(100, 35)
    $btnOK.BackColor = $primaryBlue
    $btnOK.ForeColor = $lightText
    $btnOK.FlatStyle = 'Flat'
    $btnOK.FlatAppearance.BorderSize = 0
    $btnOK.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $btnOK.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButtonPanel.Controls.Add($btnOK)


    $resultsForm.AcceptButton = $btnOK
    $resultsForm.ShowDialog() | Out-Null
}

# Run button handler
$btnRun.Add_Click({
    # Get all selected SQL files from the entire tree
    $selectedFiles = Get-SelectedSqlFilesRecursive $treeView.Nodes

    if ($selectedFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Please select at least one SQL script to run.',
            'Selection Required',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    # Get credentials if not already set or if user wants to change them
    if (-not $global:SqlCredentials) {
        $creds = Show-CredentialsForm
        if (-not $creds) {
            $statusLabel.Text = "Operation canceled - credentials not set."
            return
        }
        $global:SqlCredentials = $creds
        $credentialsStatus.Text = "Credentials: Set"
        $credentialsStatus.ForeColor = $successGreen
    }

    $statusLabel.Text = "Running $($selectedFiles.Count) selected scripts..."
    $progressBar.Visible = $true
    $progressBar.Style = 'Continuous' # Change to continuous for showing progress
    $progressBar.Maximum = $selectedFiles.Count
    $progressBar.Value = 0
    $form.Refresh() # Force UI update

    $successFiles = @()
    $failedFiles = @()

    try {
        foreach ($file in $selectedFiles) {
            $progressBar.Value++ # Increment progress bar
            $statusLabel.Text = "Running script: $($file.Name) ($($progressBar.Value)/$($selectedFiles.Count))..."
            $form.Refresh()

            try {
                # Download script content
                $scriptContent = (Invoke-WebRequest -Uri $file.DownloadUrl -Headers $Headers -UserAgent "PowerShellApp" -ErrorAction Stop).Content

                # Run SQL script
                $result = Invoke-SqlScript -ScriptContent $scriptContent `
                                         -Server $global:SqlCredentials.Server `
                                         -Database $global:SqlCredentials.Database `
                                         -Username $global:SqlCredentials.Username `
                                         -Password $global:SqlCredentials.Password

                if ($result) {
                    $successFiles += $file.Name
                } else {
                    $failedFiles += $file.Name
                }
            } catch {
                # Catch specific errors during download or single script execution
                Write-Error "Error processing script $($file.Name): $($_.Exception.Message)"
                $failedFiles += $file.Name
            }
        }

        $statusLabel.Text = "Execution completed: $($successFiles.Count) succeeded, $($failedFiles.Count) failed."

        # Show detailed results
        Show-ResultsForm $successFiles $failedFiles
    } catch {
        $statusLabel.Text = "An unexpected error occurred during script execution: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "An unexpected error occurred during script execution:`n$($_.Exception.Message)",
            'Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        $progressBar.Visible = $false
        $progressBar.Style = 'Marquee' # Reset to Marquee for future indeterminate operations
    }
})

# Credentials button handler
$btnCredentials.Add_Click({
    $creds = Show-CredentialsForm
    if ($creds) {
        $global:SqlCredentials = $creds
        $credentialsStatus.Text = "Credentials: Set"
        $credentialsStatus.ForeColor = $successGreen
        $statusLabel.Text = "Database credentials updated."
    } else {
        $statusLabel.Text = "Credentials update canceled."
    }
})

# Refresh button handler
$btnRefresh.Add_Click({
    Populate-TreeView
})

# Load folders after form shows
$form.Add_Shown({
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Populate-TreeView
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
})

# Handle form closing - prevent closing during an active operation
$form.Add_FormClosing({
    if ($progressBar.Visible) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please wait until the current operation completes before closing the application.",
            "Operation in Progress",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        $_.Cancel = $true # Cancel the closing event
    }
})

# Button hover effects - moved after button creation
$btnRun.Add_MouseEnter({ $btnRun.BackColor = $hoverBlue })
$btnRun.Add_MouseLeave({ $btnRun.BackColor = $successGreen })

$btnCredentials.Add_MouseEnter({ $btnCredentials.BackColor = $hoverBlue })
$btnCredentials.Add_MouseLeave({ $btnCredentials.BackColor = $buttonBackground })

$btnRefresh.Add_MouseEnter({ $btnRefresh.BackColor = $hoverBlue })
$btnRefresh.Add_MouseLeave({ $btnRefresh.BackColor = $buttonBackground })

# Enable visual styles for better rendering
[System.Windows.Forms.Application]::EnableVisualStyles()
# Run the application
$form.ShowDialog() | Out-Null