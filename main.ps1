# =========================
# CONFIG - GitHub Repo
# =========================
$Owner  = 'iamleoncio'
$Repo   = 'mssql_query_updates'
$Branch = 'main'
$GitHubToken = ''   # Optional. Use a fine-grained PAT. If set, we'll use Bearer.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Headers
$Headers = @{
  'User-Agent' = 'PowerShellApp'
  'Accept'     = 'application/vnd.github.v3+json'
}
if (-not [string]::IsNullOrEmpty($GitHubToken)) {
  # GitHub recommends "Bearer" for fine-grained PATs. "token" still works for classic PATs.
  $Headers['Authorization'] = "Bearer $GitHubToken"
}

# =========================
# Globals
# =========================
$global:SqlCredentials = $null
$global:UseIntegratedSecurity = $false

# =========================
# GitHub API helpers
# =========================
function Invoke-GHGet {
  param([string]$Url)
  try {
    Invoke-RestMethod -Uri $Url -Headers $Headers -ErrorAction Stop
  } catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = if ($statusCode) { "HTTP $statusCode : $($_.Exception.Response.StatusDescription)" } else { $_.Exception.Message }
    throw "GitHub API Error: $errorMsg`nURL: $Url"
  }
}

function Get-GitHubContent {
  param([string]$Path = '')
  $base = "https://api.github.com/repos/$Owner/$Repo/contents"
  $url  = if ($Path) { "$base/$([uri]::EscapeDataString($Path))?ref=$([uri]::EscapeDataString($Branch))" }
          else       { "$base?ref=$([uri]::EscapeDataString($Branch))" }

  # Debug output
  Write-Host "Testing URL: $url"

  Invoke-GHGet -Url $url
}

# Returns files (and optionally subfolders) for a path
function Get-GitHubFolderItems {
  param([string]$FolderPath)
  $items = Get-GitHubContent -Path $FolderPath
  $dirs = @()
  $sqlFiles = @()

  foreach ($item in $items) {
    if ($item.type -eq 'dir') {
      $dirs += [PSCustomObject]@{
        Name = $item.name
        Path = $item.path
        Type = 'dir'
      }
    } elseif ($item.type -eq 'file' -and $item.name -like '*.sql') {
      $sqlFiles += [PSCustomObject]@{
        Name        = $item.name
        Path        = $item.path
        DownloadUrl = $item.download_url
        Type        = 'file'
      }
    }
  }

  return [PSCustomObject]@{
    Dirs = $dirs   | Sort-Object Name
    Files = $sqlFiles | Sort-Object Name
  }
}

# =========================
# SQL helpers
# =========================
function Split-SqlBatches {
  <#
    Splits on lines where "GO" is by itself (case-insensitive),
    ignoring occurrences within other text.
  #>
  param([string]$ScriptContent)
  $pattern = "(?ms)^\s*GO\s*(?:--.*)?$"
  return [regex]::Split($ScriptContent, $pattern)
}

function Invoke-SqlScript {
  param(
    [string]$ScriptContent,
    [string]$Server,
    [string]$Database,
    [string]$Username,
    [string]$Password,
    [switch]$IntegratedSecurity
  )

  $connectionString =
    if ($IntegratedSecurity) {
      "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True;"
    } else {
      "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;TrustServerCertificate=True;"
    }

  $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
  $errors = New-Object System.Collections.Generic.List[string]

  try {
    $connection.Open()
    $batches = Split-SqlBatches -ScriptContent $ScriptContent

    foreach ($batch in $batches) {
      if (-not [string]::IsNullOrWhiteSpace($batch)) {
        $cmd = $connection.CreateCommand()
        $cmd.CommandTimeout = 0
        $cmd.CommandText = $batch
        try { [void]$cmd.ExecuteNonQuery() }
        catch {
          $errors.Add($_.Exception.Message)
        }
      }
    }

    return [PSCustomObject]@{
      Success = ($errors.Count -eq 0)
      Errors  = $errors
    }
  } catch {
    return [PSCustomObject]@{
      Success = $false
      Errors  = @("Connection/Execution error: $($_.Exception.Message)")
    }
  } finally {
    if ($connection.State -eq 'Open') { $connection.Close() }
  }
}

# =========================
# UI (WinForms)
# =========================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$darkBackground   = '#0f172a'
$cardBackground   = '#1e293b'
$primaryBlue      = '#3b82f6'
$lightText        = '#f1f5f9'
$secondaryText    = '#94a3b8'
$progressBlue     = '#60a5fa'
$buttonBackground = '#334155'
$hoverBlue        = '#93c5fd'
$successGreen     = '#10b981'
$errorRed         = '#ef4444'
$selectionColor   = '#1e3a8a'

$form = New-Object System.Windows.Forms.Form
$form.Text            = "SQL Script Runner"
$form.Size            = '980,740'
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $darkBackground
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.Padding         = New-Object System.Windows.Forms.Padding(20)

$mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$mainLayout.Dock = 'Fill'
$mainLayout.ColumnCount = 1
$mainLayout.RowCount = 3
$mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$form.Controls.Add($mainLayout)

# Header
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = 'Fill'
$headerPanel.BackColor = $darkBackground
$headerPanel.Height = 92
$mainLayout.Controls.Add($headerPanel, 0, 0)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text      = "SQL Script Runner"
$titleLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $lightText
$titleLabel.AutoSize  = $true
$titleLabel.Location  = New-Object System.Drawing.Point(20, 20)
$headerPanel.Controls.Add($titleLabel)

$repoLabel = New-Object System.Windows.Forms.Label
$repoLabel.Text      = "$Owner/$Repo : $Branch"
$repoLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$repoLabel.ForeColor = $secondaryText
$repoLabel.AutoSize  = $true
$repoLabel.Location  = New-Object System.Drawing.Point(20, 60)
$headerPanel.Controls.Add($repoLabel)

$btnCredentials = New-Object System.Windows.Forms.Button
$btnCredentials.Text       = 'SET CREDENTIALS'
$btnCredentials.Size       = New-Object System.Drawing.Size(160, 35)
$btnCredentials.BackColor  = $buttonBackground
$btnCredentials.ForeColor  = $lightText
$btnCredentials.FlatStyle  = 'Flat'
$btnCredentials.FlatAppearance.BorderSize = 0
$btnCredentials.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnCredentials.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCredentials.Location  = New-Object System.Drawing.Point(710, 18)
$headerPanel.Controls.Add($btnCredentials)

$credentialsStatus = New-Object System.Windows.Forms.Label
$credentialsStatus.Text      = "Credentials: Not Set"
$credentialsStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$credentialsStatus.ForeColor = $errorRed
$credentialsStatus.AutoSize  = $true
$credentialsStatus.Location  = New-Object System.Drawing.Point(710, 60)
$headerPanel.Controls.Add($credentialsStatus)

# Body
$scriptsPanel = New-Object System.Windows.Forms.Panel
$scriptsPanel.Dock = 'Fill'
$scriptsPanel.BackColor = $cardBackground
$scriptsPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$mainLayout.Controls.Add($scriptsPanel, 0, 1)

# TreeView
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
$treeView.ShowPlusMinus = $true
$treeView.ShowRootLines = $false
# Keep default checkbox drawing to avoid double-draw issues
$treeView.DrawMode = 'OwnerDrawText'
$scriptsPanel.Controls.Add($treeView)

$treeView.Add_DrawNode({
  param($sender, $e)
  # Let Windows draw checkbox; we custom-draw only text background for selection.
  $e.DrawDefault = $false

  $bg = New-Object System.Drawing.SolidBrush $darkBackground
  $e.Graphics.FillRectangle($bg, $e.Bounds)

  if (($e.State -band [System.Windows.Forms.TreeNodeStates]::Selected) -ne 0) {
    $sel = New-Object System.Drawing.SolidBrush $selectionColor
    $e.Graphics.FillRectangle($sel, $e.Bounds)
  }

  $textBrush = New-Object System.Drawing.SolidBrush $lightText
  $e.Graphics.DrawString($e.Node.Text, $treeView.Font, $textBrush, $e.Bounds.Left + 2, $e.Bounds.Top + 2)
})

# Footer buttons
$buttonContainer = New-Object System.Windows.Forms.Panel
$buttonContainer.Dock = 'Fill'
$buttonContainer.BackColor = $darkBackground
$buttonContainer.Height = 74
$mainLayout.Controls.Add($buttonContainer, 0, 2)

$buttonLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonLayout.Dock = 'Fill'
$buttonLayout.FlowDirection = 'RightToLeft'
$buttonLayout.Padding = New-Object System.Windows.Forms.Padding(0, 10, 20, 10)
$buttonContainer.Controls.Add($buttonLayout)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text       = 'RUN SELECTED SCRIPTS'
$btnRun.Size       = New-Object System.Drawing.Size(230, 45)
$btnRun.BackColor  = $successGreen
$btnRun.ForeColor  = $lightText
$btnRun.Enabled    = $false
$btnRun.FlatStyle  = 'Flat'
$btnRun.FlatAppearance.BorderSize = 0
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnRun)

$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text       = 'DOWNLOAD SELECTED'
$btnDownload.Size       = New-Object System.Drawing.Size(200, 45)
$btnDownload.BackColor  = $buttonBackground
$btnDownload.ForeColor  = $lightText
$btnDownload.FlatStyle  = 'Flat'
$btnDownload.FlatAppearance.BorderSize = 0
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnDownload.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnDownload.Enabled = $false
$buttonLayout.Controls.Add($btnDownload)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text       = 'REFRESH'
$btnRefresh.Size       = New-Object System.Drawing.Size(130, 45)
$btnRefresh.BackColor  = $buttonBackground
$btnRefresh.ForeColor  = $lightText
$btnRefresh.FlatStyle  = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
$buttonLayout.Controls.Add($btnRefresh)

# Status + progress
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Dock = 'Bottom'
$statusBar.BackColor = $darkBackground
$statusBar.ForeColor = $secondaryText
$statusBar.SizingGrip = $false
$statusBar.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($statusBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.ForeColor = $secondaryText
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.AutoSize = $true
$statusBar.Controls.Add($statusLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = 'Bottom'
$progressBar.Height = 6
$progressBar.Style = 'Marquee'
$progressBar.Visible = $false
$progressBar.ForeColor = $progressBlue
$form.Controls.Add($progressBar)

# =========================
# Credentials Dialog
# =========================
function Show-CredentialsForm {
  $f = New-Object System.Windows.Forms.Form
  $f.Text = "Database Credentials"
  $f.Size = '420, 360'
  $f.StartPosition = 'CenterScreen'
  $f.FormBorderStyle = 'FixedDialog'
  $f.BackColor = $darkBackground
  $f.Padding = New-Object System.Windows.Forms.Padding(20)

  $layout = New-Object System.Windows.Forms.TableLayoutPanel
  $layout.Dock = 'Fill'
  $layout.ColumnCount = 2
  $layout.RowCount = 6
  $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null
  $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70))) | Out-Null
  $f.Controls.Add($layout)

  $lbl = { param($t) $o=New-Object System.Windows.Forms.Label; $o.Text=$t; $o.ForeColor=$lightText; $o.Dock='Fill'; $o.TextAlign='MiddleRight'; $o }
  $txt = { $o=New-Object System.Windows.Forms.TextBox; $o.Dock='Fill'; $o.BackColor=$darkBackground; $o.ForeColor=$lightText; $o.BorderStyle='FixedSingle'; $o }

  $layout.Controls.Add((&$lbl "Server:"), 0, 0)
  $txtServer = &$txt
  $layout.Controls.Add($txtServer, 1, 0)

  $layout.Controls.Add((&$lbl "Database:"), 0, 1)
  $txtDatabase = &$txt
  $layout.Controls.Add($txtDatabase, 1, 1)

  $layout.Controls.Add((&$lbl "Username:"), 0, 2)
  $txtUsername = &$txt
  $layout.Controls.Add($txtUsername, 1, 2)

  $layout.Controls.Add((&$lbl "Password:"), 0, 3)
  $txtPassword = &$txt
  $txtPassword.PasswordChar = '*'
  $layout.Controls.Add($txtPassword, 1, 3)

  $chkIntegrated = New-Object System.Windows.Forms.CheckBox
  $chkIntegrated.Text = "Use Windows Authentication"
  $chkIntegrated.ForeColor = $lightText
  $chkIntegrated.AutoSize = $true
  $layout.Controls.Add($chkIntegrated, 1, 4)

  $panel = New-Object System.Windows.Forms.Panel
  $panel.Dock='Fill'
  $panel.Height=40
  $layout.Controls.Add($panel,0,5)
  $layout.SetColumnSpan($panel,2)

  $btnSave = New-Object System.Windows.Forms.Button
  $btnSave.Text = "SAVE"
  $btnSave.Size = New-Object System.Drawing.Size(100, 30)
  $btnSave.BackColor = $primaryBlue
  $btnSave.ForeColor = $lightText
  $btnSave.FlatStyle = 'Flat'
  $btnSave.FlatAppearance.BorderSize = 0
  $btnSave.Location = New-Object System.Drawing.Point(170, 5)
  $btnSave.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $panel.Controls.Add($btnSave)

  $btnCancel = New-Object System.Windows.Forms.Button
  $btnCancel.Text = "CANCEL"
  $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
  $btnCancel.BackColor = $buttonBackground
  $btnCancel.ForeColor = $lightText
  $btnCancel.FlatStyle = 'Flat'
  $btnCancel.FlatAppearance.BorderSize = 0
  $btnCancel.Location = New-Object System.Drawing.Point(280, 5)
  $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $panel.Controls.Add($btnCancel)

  $f.AcceptButton = $btnSave
  $f.CancelButton = $btnCancel

  if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    return @{
      Server = $txtServer.Text
      Database = $txtDatabase.Text
      Username = $txtUsername.Text
      Password = $txtPassword.Text
      Integrated = [bool]$chkIntegrated.Checked
    }
  }
  return $null
}

# =========================
# Tree population & events
# =========================
function Add-FolderNode {
  param($ParentNode, $FolderPath, $FolderName)

  $node = New-Object System.Windows.Forms.TreeNode($FolderName)
  $node.Tag = @{ Type='dir'; Path=$FolderPath }
  # Dummy child enables expansion arrow; we'll replace on expand.
  $node.Nodes.Add((New-Object System.Windows.Forms.TreeNode("Loading..."))) | Out-Null

  if ($ParentNode) { [void]$ParentNode.Nodes.Add($node) } else { [void]$treeView.Nodes.Add($node) }
  return $node
}

function Populate-Root {
  $statusLabel.Text = "Loading repository content..."
  $progressBar.Visible = $true
  $progressBar.Style = 'Marquee'
  $form.Refresh()

  try {
    $treeView.Nodes.Clear()
    $root = Get-GitHubContent
    foreach ($item in $root) {
      if ($item.type -eq 'dir') { Add-FolderNode -ParentNode $null -FolderPath $item.path -FolderName $item.name | Out-Null }
    }
    $statusLabel.Text = "$($treeView.Nodes.Count) folders loaded"
    $btnRun.Enabled = $false
    $btnDownload.Enabled = $false
  } catch {
    $statusLabel.Text = "Error: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show("GitHub API Error:`n$($_.Exception.Message)",'Connection Failed','OK','Error') | Out-Null
  } finally {
    $progressBar.Visible = $false
  }
}

# Expand: replace dummy with actual children (dirs + .sql files), recursively
$treeView.Add_BeforeExpand({
  $node = $_.Node
  if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading...") {
    $node.Nodes.Clear()
    try {
      $statusLabel.Text = "Loading: $($node.Text)"
      $progressBar.Visible = $true
      $form.Refresh()

      $path = $node.Tag.Path
      $items = Get-GitHubFolderItems -FolderPath $path

      foreach ($d in $items.Dirs)   { Add-FolderNode -ParentNode $node -FolderPath $d.Path -FolderName $d.Name | Out-Null }
      foreach ($f in $items.Files)  {
        $fileNode = New-Object System.Windows.Forms.TreeNode($f.Name)
        $fileNode.Tag = @{ Type='file'; Data=$f }
        [void]$node.Nodes.Add($fileNode)
      }

      $statusLabel.Text = "Loaded $($items.Dirs.Count) folders, $($items.Files.Count) scripts"
    } catch {
      $statusLabel.Text = "Error: $($_.Exception.Message)"
      [System.Windows.Forms.MessageBox]::Show("Error loading scripts:`n$($_.Exception.Message)",'Error','OK','Error') | Out-Null
    } finally {
      $progressBar.Visible = $false
    }
  }
})

# Helper: enumerate all checked file nodes (recursively)
function Get-CheckedFiles($node) {
  $selected = @()
  if ($node.Tag -and $node.Tag.Type -eq 'file' -and $node.Checked) {
    $selected += $node.Tag.Data
  }
  foreach ($child in $node.Nodes) {
    $selected += Get-CheckedFiles $child
  }
  return $selected
}

function Refresh-ActionButtons {
  $anyChecked = $false
  foreach ($n in $treeView.Nodes) {
    if ((Get-CheckedFiles $n).Count -gt 0) { $anyChecked = $true; break }
  }
  $btnRun.Enabled = $anyChecked
  $btnDownload.Enabled = $anyChecked
}

# Checkbox propagation + tri-state parent handling
function Update-Children($node, $isChecked) {
  foreach ($child in $node.Nodes) {
    $child.Checked = $isChecked
    if ($child.Nodes.Count -gt 0) { Update-Children $child $isChecked }
  }
}
function Update-Parent($node) {
  if (-not $node.Parent) { return }
  $siblings = $node.Parent.Nodes
  $allChecked = ($siblings | Where-Object { $_.Checked }).Count -eq $siblings.Count
  $anyChecked = ($siblings | Where-Object { $_.Checked }).Count -gt 0
  # WinForms TreeView doesn't support true tri-state, but we emulate:
  $node.Parent.Checked = $allChecked
  Update-Parent $node.Parent
}

$treeView.Add_AfterCheck({
  # Avoid loops from programmatic changes:
  if ($_.Action -eq [System.Windows.Forms.TreeViewAction]::Unknown) { return }

  $node = $_.Node
  if ($node.Tag -and $node.Tag.Type -eq 'dir') {
    # Expand to ensure children loaded before propagating
    if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading...") { $node.Expand() }
    Update-Children $node $node.Checked
  } else {
    Update-Parent $node
  }

  Refresh-ActionButtons
})

$treeView.Add_AfterSelect({ Refresh-ActionButtons })

# =========================
# Results dialog
# =========================
function Show-ResultsForm {
  param([string[]]$successFiles, [hashtable]$failedMap)

  $f = New-Object System.Windows.Forms.Form
  $f.Text = "Execution Results"
  $f.Size = '660, 560'
  $f.StartPosition = 'CenterParent'
  $f.FormBorderStyle = 'FixedDialog'
  $f.BackColor = $darkBackground
  $f.Padding = New-Object System.Windows.Forms.Padding(20)

  $layout = New-Object System.Windows.Forms.TableLayoutPanel
  $layout.Dock = 'Fill'
  $layout.ColumnCount = 1
  $layout.RowCount = 4
  $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
  $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 45))) | Out-Null
  $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 45))) | Out-Null
  $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
  $f.Controls.Add($layout)

  $summary = New-Object System.Windows.Forms.Label
  $summary.Text = "Success: $($successFiles.Count)  •  Failed: $($failedMap.Keys.Count)"
  $summary.ForeColor = $lightText
  $summary.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
  $summary.Dock = 'Top'
  $summary.TextAlign = 'MiddleCenter'
  $layout.Controls.Add($summary,0,0)

  $okPanel = { param($title,$color)
    $p = New-Object System.Windows.Forms.Panel
    $p.Dock = 'Fill'
    $p.BackColor = $cardBackground
    $p.Padding = New-Object System.Windows.Forms.Padding(10)
    $t = New-Object System.Windows.Forms.Label
    $t.Text = $title
    $t.ForeColor = $color
    $t.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $t.Dock='Top'
    $p.Controls.Add($t)
    $p
  }

  $p1 = & $okPanel "SUCCESSFUL SCRIPTS" $successGreen
  $lstSuccess = New-Object System.Windows.Forms.ListBox
  $lstSuccess.Dock='Fill'
  $lstSuccess.BackColor = $darkBackground
  $lstSuccess.ForeColor = $successGreen
  $lstSuccess.BorderStyle='None'
  $lstSuccess.Font = New-Object System.Drawing.Font("Segoe UI", 10)
  if ($successFiles) { $lstSuccess.Items.AddRange($successFiles) }
  $p1.Controls.Add($lstSuccess)
  $layout.Controls.Add($p1,0,1)

  $p2 = & $okPanel "FAILED SCRIPTS (double-click to view error)" $errorRed
  $lstFailed = New-Object System.Windows.Forms.ListBox
  $lstFailed.Dock='Fill'
  $lstFailed.BackColor = $darkBackground
  $lstFailed.ForeColor = $errorRed
  $lstFailed.BorderStyle='None'
  $lstFailed.Font = New-Object System.Drawing.Font("Segoe UI", 10)
  if ($failedMap.Keys.Count -gt 0) { $lstFailed.Items.AddRange($failedMap.Keys) }
  $p2.Controls.Add($lstFailed)
  $layout.Controls.Add($p2,0,2)

  $btnSaveLog = New-Object System.Windows.Forms.Button
  $btnSaveLog.Text = "Save Log"
  $btnSaveLog.Size = New-Object System.Drawing.Size(120, 36)
  $btnSaveLog.BackColor = $buttonBackground
  $btnSaveLog.ForeColor = $lightText
  $btnSaveLog.FlatStyle='Flat'
  $btnSaveLog.FlatAppearance.BorderSize=0

  $btnOK = New-Object System.Windows.Forms.Button
  $btnOK.Text = "OK"
  $btnOK.Size = New-Object System.Drawing.Size(120, 36)
  $btnOK.BackColor = $primaryBlue
  $btnOK.ForeColor = $lightText
  $btnOK.FlatStyle='Flat'
  $btnOK.FlatAppearance.BorderSize=0
  $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK

  $panelBtns = New-Object System.Windows.Forms.FlowLayoutPanel
  $panelBtns.Dock='Top'
  $panelBtns.FlowDirection='RightToLeft'
  $panelBtns.Padding = New-Object System.Windows.Forms.Padding(0,10,0,0)
  $panelBtns.Controls.Add($btnOK)
  $panelBtns.Controls.Add($btnSaveLog)
  $layout.Controls.Add($panelBtns,0,3)

  $lstFailed.Add_DoubleClick({
    if ($lstFailed.SelectedItem) {
      $file = [string]$lstFailed.SelectedItem
      $msg = ($failedMap[$file] -join "`r`n")
      [System.Windows.Forms.MessageBox]::Show($msg, "Error: $file", 'OK','Error') | Out-Null
    }
  })

  $btnSaveLog.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Text Files|*.txt"
    $sfd.FileName = "sql_run_log_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
      $lines = @()
      $lines += "SUCCESS:"
      $lines += ($successFiles | ForEach-Object { "  $_" })
      $lines += ""
      $lines += "FAILED:"
      foreach ($k in $failedMap.Keys) {
        $lines += "  $k"
        $lines += ($failedMap[$k] | ForEach-Object { "    $_" })
      }
      Set-Content -LiteralPath $sfd.FileName -Value $lines -Encoding UTF8
      [System.Windows.Forms.MessageBox]::Show("Saved: $($sfd.FileName)","Saved",'OK','Information') | Out-Null
    }
  })

  $f.AcceptButton = $btnOK
  $f.ShowDialog() | Out-Null
}

# =========================
# Actions
# =========================
function Get-AllCheckedFiles {
  $selected = @()
  foreach ($root in $treeView.Nodes) { $selected += Get-CheckedFiles $root }
  return $selected
}

$btnRun.Add_Click({
  $selectedFiles = Get-AllCheckedFiles
  if ($selectedFiles.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show('Please check at least one .sql file','Selection Required','OK','Information') | Out-Null
    return
  }

  if (-not $global:SqlCredentials) {
    $c = Show-CredentialsForm
    if (-not $c) { $statusLabel.Text = "Canceled"; return }
    $global:SqlCredentials = @{
      Server   = $c.Server
      Database = $c.Database
      Username = $c.Username
      Password = $c.Password
    }
    $global:UseIntegratedSecurity = $c.Integrated
    $credentialsStatus.Text = "Credentials: Set"
    $credentialsStatus.ForeColor = $successGreen
  }

  $statusLabel.Text = "Running $($selectedFiles.Count) scripts..."
  $progressBar.Visible = $true
  $progressBar.Style = 'Continuous'
  $progressBar.Maximum = $selectedFiles.Count
  $progressBar.Value = 0
  $form.Refresh()

  $success = New-Object System.Collections.Generic.List[string]
  $failed  = @{} # fileName -> errors[]

  try {
    foreach ($file in $selectedFiles) {
      $progressBar.Value++
      $statusLabel.Text = "Running: $($file.Name) ($($progressBar.Value)/$($selectedFiles.Count))"
      $form.Refresh()

      try {
        $scriptContent = (Invoke-WebRequest -Uri $file.DownloadUrl -Headers $Headers).Content
        $res = Invoke-SqlScript -ScriptContent $scriptContent `
          -Server $global:SqlCredentials.Server `
          -Database $global:SqlCredentials.Database `
          -Username $global:SqlCredentials.Username `
          -Password $global:SqlCredentials.Password `
          -IntegratedSecurity:($global:UseIntegratedSecurity)

        if ($res.Success) { $success.Add($file.Name) }
        else { $failed[$file.Name] = $res.Errors }
      } catch {
        $failed[$file.Name] = @("Download/Execution error: $($_.Exception.Message)")
      }
    }

    $statusLabel.Text = "Done: $($success.Count) succeeded, $($failed.Keys.Count) failed"
    Show-ResultsForm -successFiles $success.ToArray() -failedMap $failed
  } catch {
    $statusLabel.Text = "Error: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show("Error running scripts:`n$($_.Exception.Message)",'Error','OK','Error') | Out-Null
  } finally {
    $progressBar.Visible = $false
  }
})

$btnDownload.Add_Click({
  $selectedFiles = Get-AllCheckedFiles
  if ($selectedFiles.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show('Please check at least one .sql file','Selection Required','OK','Information') | Out-Null
    return
  }

  $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
  $fbd.Description = "Choose a folder to save SQL files"
  if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

  $statusLabel.Text = "Downloading $($selectedFiles.Count) files..."
  $progressBar.Visible = $true
  $progressBar.Style = 'Continuous'
  $progressBar.Maximum = $selectedFiles.Count
  $progressBar.Value = 0
  $form.Refresh()

  $fail = New-Object System.Collections.Generic.List[string]
  foreach ($file in $selectedFiles) {
    $progressBar.Value++
    $statusLabel.Text = "Downloading: $($file.Name) ($($progressBar.Value)/$($selectedFiles.Count))"
    $form.Refresh()
    try {
      $content = (Invoke-WebRequest -Uri $file.DownloadUrl -Headers $Headers).Content
      $dest = Join-Path $fbd.SelectedPath $file.Name
      Set-Content -LiteralPath $dest -Value $content -Encoding UTF8
    } catch {
      $fail.Add($file.Name)
    }
  }

  $progressBar.Visible = $false
  if ($fail.Count -gt 0) {
    [System.Windows.Forms.MessageBox]::Show("Downloaded with errors. Failed: `n$($fail -join "`r`n")",'Download','OK','Warning') | Out-Null
  } else {
    [System.Windows.Forms.MessageBox]::Show("All selected files downloaded to:`n$($fbd.SelectedPath)",'Download','OK','Information') | Out-Null
  }
  $statusLabel.Text = "Ready"
})

$btnCredentials.Add_Click({
  $c = Show-CredentialsForm
  if ($c) {
    $global:SqlCredentials = @{
      Server   = $c.Server
      Database = $c.Database
      Username = $c.Username
      Password = $c.Password
    }
    $global:UseIntegratedSecurity = $c.Integrated
    $credentialsStatus.Text = "Credentials: Set"
    $credentialsStatus.ForeColor = $successGreen
    $statusLabel.Text = "Database credentials updated"
  } else {
    $statusLabel.Text = "Credentials update canceled"
  }
})

$btnRefresh.Add_Click({ Populate-Root })

# Hover effects
$btnRun.Add_MouseEnter({ $btnRun.BackColor = $hoverBlue })
$btnRun.Add_MouseLeave({ $btnRun.BackColor = $successGreen })

$btnCredentials.Add_MouseEnter({ $btnCredentials.BackColor = $hoverBlue })
$btnCredentials.Add_MouseLeave({ $btnCredentials.BackColor = $buttonBackground })

$btnRefresh.Add_MouseEnter({ $btnRefresh.BackColor = $hoverBlue })
$btnRefresh.Add_MouseLeave({ $btnRefresh.BackColor = $buttonBackground })

$btnDownload.Add_MouseEnter({ $btnDownload.BackColor = $hoverBlue })
$btnDownload.Add_MouseLeave({ $btnDownload.BackColor = $buttonBackground })

$form.Add_Shown({
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  Populate-Root
  $form.Cursor = [System.Windows.Forms.Cursors]::Default
})

$form.Add_FormClosing({
  if ($progressBar.Visible) {
    [System.Windows.Forms.MessageBox]::Show("Please wait until the current operation completes","Operation in Progress",'OK','Warning') | Out-Null
    $_.Cancel = $true
  }
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog() | Out-Null
