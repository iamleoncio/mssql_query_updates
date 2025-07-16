Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sir Pao Uwi ka na !"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"
$form.BackColor = 'White'

# Create label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Welcome to Apps Knowledge"
$label.AutoSize = $true
$label.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$label.Location = New-Object System.Drawing.Point(50, 60)

# Add label to form
$form.Controls.Add($label)

# Show the form
$form.ShowDialog()
