Add-Type -AssemblyName System.Drawing

function New-Icon {
    param([int]$Size, [string]$OutPath, [bool]$Maskable = $false)

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $bgColor = [System.Drawing.ColorTranslator]::FromHtml('#e26ba8')
    $bg = New-Object System.Drawing.SolidBrush($bgColor)

    if ($Maskable) {
        $g.FillRectangle($bg, 0, 0, $Size, $Size)
    } else {
        $r = [int]($Size * 0.22)
        $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $gp.AddArc(0, 0, $r*2, $r*2, 180, 90)
        $gp.AddArc($Size - $r*2, 0, $r*2, $r*2, 270, 90)
        $gp.AddArc($Size - $r*2, $Size - $r*2, $r*2, $r*2, 0, 90)
        $gp.AddArc(0, $Size - $r*2, $r*2, $r*2, 90, 90)
        $gp.CloseFigure()
        $g.FillPath($bg, $gp)
        $gp.Dispose()
    }

    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $deepBrush  = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#c44d8a'))
    $deepPen    = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#c44d8a'), [single]([Math]::Max(2, $Size * 0.045)))
    $deepPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $deepPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $whitePen   = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [single]([Math]::Max(2, $Size * 0.05)))
    $whitePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $whitePen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

    # Stopwatch: body circle, top stem button, two hands, center dot.
    $safe = if ($Maskable) { 0.60 } else { 0.72 }
    $faceR = [single](($Size * $safe) / 2)
    $cx    = [single]($Size / 2)
    $cy    = [single]($Size / 2 + $Size * 0.05)   # nudge down to leave room for stem

    # Top crown bar (small rect on top of the stem)
    $crownW = [single]($faceR * 0.55)
    $crownH = [single]($faceR * 0.14)
    $g.FillRectangle($whiteBrush,
        [single]($cx - $crownW / 2),
        [single]($cy - $faceR - $faceR * 0.32),
        $crownW, $crownH)

    # Stem (between crown and body)
    $stemW = [single]($faceR * 0.30)
    $stemH = [single]($faceR * 0.22)
    $g.FillRectangle($whiteBrush,
        [single]($cx - $stemW / 2),
        [single]($cy - $faceR - $stemH * 0.55),
        $stemW, $stemH)

    # Side crown stub (decorative diagonal nub on the upper right)
    if ($Size -ge 96) {
        $g.DrawLine($whitePen,
            [single]($cx + $faceR * 0.78),
            [single]($cy - $faceR * 0.78),
            [single]($cx + $faceR * 1.05),
            [single]($cy - $faceR * 1.02))
    }

    # Body circle
    $g.FillEllipse($whiteBrush,
        [single]($cx - $faceR),
        [single]($cy - $faceR),
        [single]($faceR * 2),
        [single]($faceR * 2))

    # Tick at 12 o'clock
    if ($Size -ge 96) {
        $tickW = [single]([Math]::Max(2, $faceR * 0.10))
        $tickH = [single]([Math]::Max(3, $faceR * 0.18))
        $g.FillRectangle($deepBrush,
            [single]($cx - $tickW / 2),
            [single]($cy - $faceR + $faceR * 0.08),
            $tickW, $tickH)
    }

    # Hands: minute hand straight up, hour hand at ~2 o'clock
    $minLen  = [single]($faceR * 0.62)
    $hourLen = [single]($faceR * 0.46)
    $angleDeg = 60.0
    $rad = $angleDeg * [Math]::PI / 180.0
    $hx = [single]($cx + $hourLen * [Math]::Cos(-$rad))
    $hy = [single]($cy - $hourLen * [Math]::Sin($rad))

    # Minute hand (up)
    $g.DrawLine($deepPen, $cx, $cy, $cx, [single]($cy - $minLen))
    # Hour hand
    $g.DrawLine($deepPen, $cx, $cy, $hx, $hy)

    # Center dot
    $dotR = [single]([Math]::Max(2, $faceR * 0.11))
    $g.FillEllipse($deepBrush,
        [single]($cx - $dotR),
        [single]($cy - $dotR),
        [single]($dotR * 2),
        [single]($dotR * 2))

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    $whiteBrush.Dispose()
    $deepBrush.Dispose()
    $deepPen.Dispose()
    $whitePen.Dispose()
    $bg.Dispose()
    Write-Host "Wrote $OutPath"
}

$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
foreach ($name in @('icon-192.png','icon-512.png','icon-512-maskable.png','apple-touch-icon.png','favicon-32.png')) {
    $p = Join-Path $dir $name
    if (Test-Path $p) { Remove-Item $p -Force }
}

New-Icon -Size 192 -OutPath (Join-Path $dir 'icon-192.png') -Maskable $false
New-Icon -Size 512 -OutPath (Join-Path $dir 'icon-512.png') -Maskable $false
New-Icon -Size 512 -OutPath (Join-Path $dir 'icon-512-maskable.png') -Maskable $true
New-Icon -Size 180 -OutPath (Join-Path $dir 'apple-touch-icon.png') -Maskable $false
New-Icon -Size 32  -OutPath (Join-Path $dir 'favicon-32.png') -Maskable $false
