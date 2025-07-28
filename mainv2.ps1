#region CONFIGURATION
# Verify these details match your GitHub repository
$Owner       = 'iamleoncio'
$Repo        = 'mssql_query_updates'
$Branch      = 'main'
$GitHubToken = '' # Optional: Add personal access token if needed
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#endregion

#region GITHUB & SQL FUNCTIONS

# Create headers with authentication if a token is provided
$Headers = @{
    'User-Agent' = 'PowerShellApp'
    'Accept'     = 'application/vnd.github.v3+json'
}
if (-not [string]::IsNullOrEmpty($GitHubToken)) {
    $Headers['Authorization'] = "token $GitHubToken"
}

# Global variable for SQL credentials
$global:SqlCredentials = $null
# Global flag to prevent recursive check events
$global:isUpdatingChecks = $false

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
    # Efficiently filter and create objects
    $sqlFiles = foreach ($item in $items) {
        if ($item.type -eq 'file' -and $item.name -like '*.sql') {
            [PSCustomObject]@{
                Name        = $item.name
                Path        = $item.path
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
    
    $connection = $null
    try {
        $connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;Connection Timeout=15;"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        # Split script by "GO" on its own line (case-insensitive)
        $batches = $ScriptContent -split '(?im)^\s*GO\s*$'
        
        foreach ($batch in $batches) {
            if (-not [string]::IsNullOrWhiteSpace($batch)) {
                $command = $connection.CreateCommand()
                $command.CommandText = $batch
                $command.ExecuteNonQuery() | Out-Null
            }
        }
        
        # Return a success result object
        return [PSCustomObject]@{ Success = $true; ErrorMessage = '' }
    } catch {
        # Return a failure result object with the specific error
        return [PSCustomObject]@{ Success = $false; ErrorMessage = $_.Exception.Message }
    } finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}
#endregion

#region GUI SETUP
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Modern color palette
$darkBackground = '#0f172a' # Deep navy background
$cardBackground = '#1e293b' # Card background
$primaryBlue    = '#3b82f6' # Vibrant blue
$lightText      = '#f1f5f9' # Soft white text
$secondaryText  = '#94a3b8' # Grayish-blue text
$progressBlue   = '#60a5fa' # Light blue for progress
$buttonBg       = '#334155' # Button background
$hoverBlue      = '#2563eb' # Darker blue for hover
$successGreen   = '#10b981' # Success green
$errorRed       = '#ef4444' # Error red
$selectionColor = '#1e40af' # Selection highlight blue
$lineColor      = '#334155' # Line color for TreeView

# Create reusable drawing resources for performance
$brushLightText = New-Object System.Drawing.SolidBrush($lightText)
$brushDarkBg = New-Object System.Drawing.SolidBrush($darkBackground)
$brushCardBg = New-Object System.Drawing.SolidBrush($cardBackground)
$brushSelection = New-Object System.Drawing.SolidBrush($selectionColor)

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL Script Runner"
$form.Size = '900,720'
$form.StartPosition = 'CenterScreen'
$form.BackColor = $darkBackground
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Padding = New-Object System.Windows.Forms.Padding(20)

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
$headerPanel.Height = 90
$mainLayout.Controls.Add($headerPanel, 0, 0)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "SQL Script Runner"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $lightText
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(0, 15)
$headerPanel.Controls.Add($titleLabel)

# Repo Info
$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text = "$Owner/$Repo : $Branch"
$repoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$repoLabel.ForeColor = $secondaryText
$repoLabel.AutoSize = $true
$repoLabel.Location = New-Object System.Drawing.Point(0, 55)
$headerPanel.Controls.Add($repoLabel)

# Credentials Button
$btnCredentials = New-Object System.Windows.Forms.Button
$btnCredentials.Text = 'SET CREDENTIALS'
$btnCredentials.Size = New-Object System.Drawing.Size(150, 35)
$btnCredentials.BackColor = $buttonBg
$btnCredentials.ForeColor = $lightText
$btnCredentials.FlatStyle = 'Flat'
$btnCredentials.FlatAppearance.BorderSize = 0
$btnCredentials.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$btnCredentials.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCredentials.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnCredentials.Location = New-Object System.Drawing.Point($form.ClientSize.Width - $btnCredentials.Width - 40, 20)
$headerPanel.Controls.Add($btnCredentials)

# Credentials Status
$credentialsStatus = New-Object System.Windows.Forms.Label
$credentialsStatus.Text = "Credentials: Not Set"
$credentialsStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$credentialsStatus.ForeColor = $errorRed
$credentialsStatus.AutoSize = $true
$credentialsStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$credentialsStatus.Location = New-Object System.Drawing.Point($form.ClientSize.Width - $credentialsStatus.Width - 40, 60)
$headerPanel.Controls.Add($credentialsStatus)

# Scripts Panel
$scriptsPanel = New-Object System.Windows.Forms.Panel
$scriptsPanel.Dock = 'Fill'
$scriptsPanel.BackColor = $cardBackground
$scriptsPanel.Padding = New-Object System.Windows.Forms.Padding(1)
$mainLayout.Controls.Add($scriptsPanel, 0, 1)

# TreeView for Scripts
$treeView = New-Object System.Windows.Forms.TreeView
$treeView.Dock = 'Fill'
$treeView.CheckBoxes = $true
$treeView.BackColor = $darkBackground
$treeView.ForeColor = $lightText
$treeView.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$treeView.BorderStyle = 'None'
$treeView.FullRowSelect = $true
$treeView.HideSelection = $false
$treeView.ItemHeight = 30
$treeView.DrawMode = 'OwnerDrawText'
$treeView.LineColor = $lineColor
$scriptsPanel.Controls.Add($treeView)

# Add icons
try {
    $imageList = New-Object System.Windows.Forms.ImageList
    $imageList.ImageSize = New-Object System.Drawing.Size(20, 20)
    $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\explorer.exe")
    $fileIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\System32\imageres.dll") # A generic document icon
    $imageList.Images.Add("Folder", $folderIcon) | Out-Null
    $imageList.Images.Add("SQL", $fileIcon) | Out-Null
    $treeView.ImageList = $imageList
} catch {} # Continue without icons if extraction fails

# Button Container
$buttonContainer = New-Object System.Windows.Forms.Panel
$buttonContainer.Dock = 'Fill'
$buttonContainer.BackColor = $darkBackground
$buttonContainer.Height = 80
$mainLayout.Controls.Add($buttonContainer, 0, 2)

# Button Layout
$buttonLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonLayout.Dock = 'Fill'
$buttonLayout.FlowDirection = 'RightToLeft'
$buttonLayout.Padding = New-Object System.Windows.Forms.Padding(0, 15, 0, 10)
$buttonContainer.Controls.Add($buttonLayout)

# Run Button
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = 'RUN CHECKED SCRIPTS'
$btnRun.Size = New-Object System.Drawing.Size(220, 45)
$btnRun.BackColor = $successGreen
$btnRun.ForeColor = $lightText
$btnRun.Enabled = $false
$btnRun.FlatStyle = 'Flat'
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnRun)

# Refresh Button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = 'REFRESH'
$btnRefresh.Size = New-Object System.Drawing.Size(120, 45)
$btnRefresh.BackColor = $buttonBg
$btnRefresh.ForeColor = $lightText
$btnRefresh.FlatStyle = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnRefresh)

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Dock = 'Bottom'
$statusBar.BackColor = $darkBackground
$statusBar.ForeColor = $secondaryText
$statusBar.SizingGrip = $false
$statusBar.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($statusBar)
$statusBar.ShowPanels = $true
$statusPanel = New-Object System.Windows.Forms.StatusBarPanel
$statusPanel.AutoSize = 'Spring'
$statusPanel.Text = "Ready"
$statusBar.Panels.Add($statusPanel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = 'Bottom'
$progressBar.Height = 5
$progressBar.Style = 'Continuous'
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

#endregion

#region GUI HELPER FUNCTIONS
function Show-CredentialsForm {
    # Form definition remains largely the same, but with improved styling
    $credentialsForm = New-Object System.Windows.Forms.Form
    $credentialsForm.Text = "Database Credentials"
    $credentialsForm.Size = '420, 320'
    $credentialsForm.StartPosition = 'CenterParent'
    $credentialsForm.FormBorderStyle = 'FixedDialog'
    $credentialsForm.BackColor = $darkBackground
    $credentialsForm.Padding = New-Object System.Windows.Forms.Padding(20)
    
    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = 'Fill'
    $layout.ColumnCount = 2
    $layout.RowCount = 5
    $credentialsForm.Controls.Add($layout)
    
    # Define labels and textboxes
    $controls = @{
        'Server:'   = New-Object System.Windows.Forms.TextBox
        'Database:' = New-Object System.Windows.Forms.TextBox
        'Username:' = New-Object System.Windows.Forms.TextBox
        'Password:' = New-Object System.Windows.Forms.TextBox
    }
    
    $i = 0
    foreach ($key in $controls.Keys) {
        $label = New-Object System.Windows.Forms.Label -Property @{ Text = $key; ForeColor = $lightText; Dock = 'Fill'; TextAlign = 'MiddleRight'; Font = "Segoe UI, 10" }
        $textbox = $controls[$key]
        $textbox.Dock = 'Fill'
        $textbox.BackColor = $cardBackground
        $textbox.ForeColor = $lightText
        $textbox.Font = "Segoe UI, 10"
        $textbox.BorderStyle = 'FixedSingle'
        $textbox.Margin = New-Object System.Windows.Forms.Padding(5)
        if ($key -eq 'Password:') { $textbox.PasswordChar = '*' }
        
        $layout.Controls.Add($label, 0, $i)
        $layout.Controls.Add($textbox, 1, $i)
        $i++
    }
    
    # Buttons
    $btnSave = New-Object System.Windows.Forms.Button -Property @{ Text = "SAVE"; DialogResult = 'OK'; BackColor = $primaryBlue; ForeColor = $lightText; FlatStyle = 'Flat'; Size = '100, 35'; Font = "Segoe UI Semibold, 10" }
    $btnSave.FlatAppearance.BorderSize = 0
    $btnCancel = New-Object System.Windows.Forms.Button -Property @{ Text = "CANCEL"; DialogResult = 'Cancel'; BackColor = $buttonBg; ForeColor = $lightText; FlatStyle = 'Flat'; Size = '100, 35'; Font = "Segoe UI Semibold, 10" }
    $btnCancel.FlatAppearance.BorderSize = 0

    $buttonFlow = New-Object System.Windows.Forms.FlowLayoutPanel -Property @{ Dock = 'Fill'; FlowDirection = 'RightToLeft' }
    $buttonFlow.Controls.Add($btnCancel)
    $buttonFlow.Controls.Add($btnSave)
    $layout.Controls.Add($buttonFlow, 0, 4)
    $layout.SetColumnSpan($buttonFlow, 2)
    
    $credentialsForm.AcceptButton = $btnSave
    $credentialsForm.CancelButton = $btnCancel
    
    if ($credentialsForm.ShowDialog($form) -eq 'OK') {
        return @{
            Server   = $controls['Server:'].Text
            Database = $controls['Database:'].Text
            Username = $controls['Username:'].Text
            Password = $controls['Password:'].Text
        }
    }
    return $null
}

function Show-ResultsForm($successFiles, $failedFiles) {
    $resultsForm = New-Object System.Windows.Forms.Form
    $resultsForm.Text = "Execution Results"
    $resultsForm.Size = '700, 550'
    $resultsForm.StartPosition = 'CenterParent'
    $resultsForm.MinimumSize = '600, 400'
    $resultsForm.BackColor = $darkBackground
    $resultsForm.Padding = New-Object System.Windows.Forms.Padding(15)

    $mainTable = New-Object System.Windows.Forms.TableLayoutPanel -Property @{ Dock = 'Fill'; ColumnCount = 1; RowCount = 4 }
    $mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
    $mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null
    $mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null
    $mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
    $resultsForm.Controls.Add($mainTable)

    $summary = New-Object System.Windows.Forms.Label -Property @{ Text = "Success: $($successFiles.Count), Failed: $($failedFiles.Count)"; ForeColor = $lightText; Font = "Segoe UI, 12, Bold"; Dock = 'Fill'; TextAlign = 'MiddleCenter'; Padding = "0,0,0,10" }
    $mainTable.Controls.Add($summary, 0, 0)

    # Success List
    $successGroup = New-Object System.Windows.Forms.GroupBox -Property @{ Text = "Successful Scripts"; ForeColor = $successGreen; Dock = 'Fill'; Font = "Segoe UI, 10, Bold" }
    $successList = New-Object System.Windows.Forms.ListBox -Property @{ BackColor = $cardBackground; ForeColor = $lightText; BorderStyle = 'None'; Dock = 'Fill'; Font = "Segoe UI, 10"; IntegralHeight = $false }
    $successList.Items.AddRange($successFiles)
    $successGroup.Controls.Add($successList)
    $mainTable.Controls.Add($successGroup, 0, 1)

    # Failed List (ListView for details)
    $failedGroup = New-Object System.Windows.Forms.GroupBox -Property @{ Text = "Failed Scripts"; ForeColor = $errorRed; Dock = 'Fill'; Font = "Segoe UI, 10, Bold" }
    $failedList = New-Object System.Windows.Forms.ListView -Property @{ BackColor = $cardBackground; ForeColor = $lightText; BorderStyle = 'None'; Dock = 'Fill'; Font = "Segoe UI, 10"; View = 'Details'; FullRowSelect = $true }
    $failedList.Columns.Add("File", 250) | Out-Null
    $failedList.Columns.Add("Error Message", 400) | Out-Null
    foreach($failure in $failedFiles) {
        $item = New-Object System.Windows.Forms.ListViewItem($failure.Name)
        $item.SubItems.Add($failure.Error) | Out-Null
        $failedList.Items.Add($item) | Out-Null
    }
    $failedGroup.Controls.Add($failedList)
    $mainTable.Controls.Add($failedGroup, 0, 2)

    # OK Button
    $btnOK = New-Object System.Windows.Forms.Button -Property @{ Text = "OK"; DialogResult = 'OK'; Size = '120, 40'; BackColor = $primaryBlue; ForeColor = $lightText; Font = "Segoe UI Semibold, 10"; FlatStyle = 'Flat'; Anchor = 'Right' }
    $btnOK.FlatAppearance.BorderSize = 0
    $okPanel = New-Object System.Windows.Forms.FlowLayoutPanel -Property @{ Dock = 'Fill'; FlowDirection = 'RightToLeft'; Padding = "0,10,0,0" }
    $okPanel.Controls.Add($btnOK)
    $mainTable.Controls.Add($okPanel, 0, 3)

    $resultsForm.AcceptButton = $btnOK
    $resultsForm.ShowDialog($form) | Out-Null
}

function Populate-TreeView {
    $statusPanel.Text = "Loading repository content..."
    $progressBar.Visible = $true
    $progressBar.Style = 'Marquee'
    $form.Refresh()
    
    try {
        $treeView.BeginUpdate()
        $treeView.Nodes.Clear()
        $content = Get-GitHubContent
        
        $folders = $content | Where-Object { $_.type -eq 'dir' } | Sort-Object Name
        foreach ($item in $folders) {
            $folderNode = New-Object System.Windows.Forms.TreeNode($item.name)
            $folderNode.Tag = $item.path
            $folderNode.ImageKey = "Folder"
            $folderNode.SelectedImageKey = "Folder"
            
            # Add a dummy node to enable the expand arrow
            $dummyNode = New-Object System.Windows.Forms.TreeNode("Loading...")
            $folderNode.Nodes.Add($dummyNode) | Out-Null
            $treeView.Nodes.Add($folderNode) | Out-Null
        }
        
        $statusPanel.Text = "Ready. Found $($folders.Count) folders."
        Update-RunButtonState # Update button state after loading
    } catch {
        $statusPanel.Text = "Error: Failed to load repository."
        [System.Windows.Forms.MessageBox]::Show($form, "Could not load repository content from GitHub.`n`nError: $($_.Exception.Message)", 'Connection Failed', 'OK', 'Error') | Out-Null
    } finally {
        $progressBar.Visible = $false
        $treeView.EndUpdate()
    }
}

function Get-CheckedFiles($nodes) {
    $checkedFiles = @()
    foreach ($node in $nodes) {
        # If it's a file node and it's checked, add its tag
        if ($node.Tag -is [PSCustomObject] -and $node.Checked) {
            $checkedFiles += $node.Tag
        }
        # Recurse into child nodes if they exist
        if ($node.Nodes.Count -gt 0) {
            $checkedFiles += Get-CheckedFiles $node.Nodes
        }
    }
    return $checkedFiles
}

function Update-RunButtonState {
    $checkedFiles = Get-CheckedFiles $treeView.Nodes
    $btnRun.Enabled = ($checkedFiles.Count -gt 0 -and $global:SqlCredentials)
    if (-not $global:SqlCredentials) {
         $btnRun.Enabled = $false
         $btnRun.Text = 'SET CREDENTIALS FIRST'
    } elseif ($checkedFiles.Count -gt 0) {
        $btnRun.Enabled = $true
        $btnRun.Text = "RUN $($checkedFiles.Count) CHECKED SCRIPTS"
    } else {
        $btnRun.Enabled = $false
        $btnRun.Text = 'RUN CHECKED SCRIPTS'
    }
}
#endregion

#region GUI EVENTS

# Custom TreeView Node Drawing
$treeView.Add_DrawNode({
    param($sender, $e)
    $e.DrawDefault = $false # We are doing all the drawing
    $node = $e.Node
    
    # Determine background brush
    $bgBrush = if (($e.State -band [System.Windows.Forms.TreeNodeStates]::Selected) -ne 0) { $brushSelection }
                elseif ($node.ImageKey -eq 'SQL') { $brushDarkBg } 
                else { $brushCardBg }
    
    $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
    
    # Draw Checkbox
    $checkSize = [System.Windows.Forms.CheckBoxRenderer]::GetGlyphSize($e.Graphics, 'CheckedNormal')
    $checkPoint = New-Object System.Drawing.Point($e.Bounds.Left + 4, $e.Bounds.Top + ($e.Bounds.Height - $checkSize.Height) / 2)
    $checkState = if ($node.Checked) { 'CheckedNormal' } else { 'UncheckedNormal' }
    [System.Windows.Forms.CheckBoxRenderer]::DrawCheckBox($e.Graphics, $checkPoint, [System.Windows.Forms.VisualStyles.CheckBoxState]::$checkState)
    
    $offsetX = $checkPoint.X + $checkSize.Width + 4
    
    # Draw Icon
    if ($treeView.ImageList -ne $null -and $node.ImageKey -ne $null -and $treeView.ImageList.Images.ContainsKey($node.ImageKey)) {
        $image = $treeView.ImageList.Images[$node.ImageKey]
        $imagePoint = New-Object System.Drawing.Point($offsetX, $e.Bounds.Top + ($e.Bounds.Height - $image.Height) / 2)
        $e.Graphics.DrawImage($image, $imagePoint)
        $offsetX += $image.Width + 5
    }

    # Draw Text
    $textPoint = New-Object System.Drawing.PointF($offsetX, $e.Bounds.Top + ($e.Bounds.Height - $treeView.Font.Height) / 2)
    $e.Graphics.DrawString($node.Text, $treeView.Font, $brushLightText, $textPoint)
})

# Load child nodes on expand
$treeView.Add_BeforeExpand({
    $node = $_.Node
    # Check if it's the first time expanding (dummy node exists)
    if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading...") {
        $node.Nodes.Clear()
        $statusPanel.Text = "Loading scripts for: $($node.Text)"
        $progressBar.Visible = $true
        $form.Refresh()
        try {
            $sqlFiles = Get-SqlFilesInFolder -FolderPath $node.Tag
            foreach ($file in $sqlFiles) {
                $fileNode = New-Object System.Windows.Forms.TreeNode($file.Name)
                $fileNode.Tag = $file
                $fileNode.ImageKey = "SQL"
                $fileNode.SelectedImageKey = "SQL"
                $node.Nodes.Add($fileNode) | Out-Null
            }
            $statusPanel.Text = "Loaded $($sqlFiles.Count) scripts in $($node.Text)"
        } catch {
            $statusPanel.Text = "Error loading scripts."
            [System.Windows.Forms.MessageBox]::Show($form, "Error loading scripts.`n`n$($_.Exception.Message)", 'Error', 'OK', 'Error') | Out-Null
        } finally {
            $progressBar.Visible = $false
        }
    }
})

# Handle checkbox logic
$treeView.Add_AfterCheck({
    param($sender, $e)
    # If we are programmatically updating, do nothing.
    if ($global:isUpdatingChecks) { return }

    $node = $e.Node
    $global:isUpdatingChecks = $true
    $treeView.BeginUpdate()
    
    # 1. Propagate check down to children
    if ($node.Nodes.Count -gt 0) {
        # Auto-expand if not already populated
        if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading...") { $node.Expand() }
        foreach ($child in $node.Nodes) {
            $child.Checked = $node.Checked
        }
    }

    # 2. Update parent's check state
    $parent = $node.Parent
    if ($parent) {
        if (-not $node.Checked) {
            # If a child is unchecked, the parent must be unchecked.
            $parent.Checked = $false
        } else {
            # If a child is checked, check the parent only if all siblings are also checked.
            $allChildrenChecked = $true
            foreach ($sibling in $parent.Nodes) {
                if (-not $sibling.Checked) {
                    $allChildrenChecked = $false
                    break
                }
            }
            $parent.Checked = $allChildrenChecked
        }
    }
    
    $treeView.EndUpdate()
    $global:isUpdatingChecks = $false
    Update-RunButtonState
})

# Run button click handler
$btnRun.Add_Click({
    $checkedFiles = Get-CheckedFiles $treeView.Nodes
    if ($checkedFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show($form, 'Please check at least one SQL script to run.', 'No Scripts Checked', 'OK', 'Information') | Out-Null
        return
    }
    
    $statusPanel.Text = "Starting execution..."
    $progressBar.Visible = $true
    $progressBar.Maximum = $checkedFiles.Count
    $progressBar.Value = 0
    $form.Cursor = 'WaitCursor'
    $btnRun.Enabled = $false
    $btnRefresh.Enabled = $false
    
    $successFiles = @()
    $failedFiles = @()
    
    try {
        foreach ($file in $checkedFiles) {
            $progressBar.Value++
            $statusPanel.Text = "Executing: $($file.Name) ($($progressBar.Value)/$($checkedFiles.Count))"
            $form.Refresh()
            
            try {
                $scriptContent = (Invoke-WebRequest -Uri $file.DownloadUrl -Headers $Headers).Content
                $result = Invoke-SqlScript -ScriptContent $scriptContent -Server $global:SqlCredentials.Server -Database $global:SqlCredentials.Database -Username $global:SqlCredentials.Username -Password $global:SqlCredentials.Password
                
                if ($result.Success) {
                    $successFiles += $file.Name
                } else {
                    $failedFiles += @{ Name = $file.Name; Error = $result.ErrorMessage }
                }
            } catch {
                $failedFiles += @{ Name = $file.Name; Error = "Failed to download or execute: $($_.Exception.Message)" }
            }
        }
        $statusPanel.Text = "Execution complete. Success: $($successFiles.Count), Failed: $($failedFiles.Count)."
        Show-ResultsForm -successFiles $successFiles -failedFiles $failedFiles
    }
    finally {
        $progressBar.Visible = $false
        $form.Cursor = 'Default'
        $btnRefresh.Enabled = $true
        Update-RunButtonState
    }
})

# Credentials button click handler
$btnCredentials.Add_Click({
    $creds = Show-CredentialsForm
    if ($creds) {
        $global:SqlCredentials = $creds
        $credentialsStatus.Text = "Credentials: Set"
        $credentialsStatus.ForeColor = $successGreen
        $credentialsStatus.Location = New-Object System.Drawing.Point($form.ClientSize.Width - $credentialsStatus.Width - 40, 60)
        $statusPanel.Text = "Database credentials saved for this session."
    } else {
        $statusPanel.Text = "Credentials update canceled."
    }
    Update-RunButtonState
})

# Refresh button click handler
$btnRefresh.Add_Click({
    Populate-TreeView
})

# Initial load when form is shown
$form.Add_Shown({
    $form.Cursor = 'WaitCursor'
    Populate-TreeView
    $form.Cursor = 'Default'
})

# Prevent closing while an operation is running
$form.Add_FormClosing({
    if ($progressBar.Visible) {
        [System.Windows.Forms.MessageBox]::Show($form, "Please wait for the current operation to complete before closing.", "Operation in Progress", 'OK', 'Warning') | Out-Null
        $_.Cancel = $true
    }
})

# Button hover effects for better UX
$buttons = @($btnRun, $btnRefresh, $btnCredentials)
foreach ($button in $buttons) {
    $originalColor = $button.BackColor
    $button.Add_MouseEnter({ $button.BackColor = $hoverBlue })
    $button.Add_MouseLeave({ $button.BackColor = $originalColor })
}
#endregion

#region SHOW FORM
[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()

# Clean up disposable resources
$form.Dispose()
$brushLightText.Dispose()
$brushDarkBg.Dispose()
$brushCardBg.Dispose()
$brushSelection.Dispose()
#endregion