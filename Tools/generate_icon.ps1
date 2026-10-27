# Generates the 1024x1024 bycreep app icon without external dependencies.
# Run on Windows: powershell -ExecutionPolicy Bypass -File Tools/generate_icon.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$size = 1024
# 24bpp keeps the PNG fully opaque: App Store validation rejects app icons
# that carry an alpha channel.
$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$full = New-Object System.Drawing.Rectangle(0, 0, $size, $size)

# Near-black background with a faint red haze in the upper-right corner.
$background = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 7, 7, 8))
$g.FillRectangle($background, $full)

# Keep the field genuinely black; the only red bloom is around the training day.
$hazeTop = [System.Drawing.Color]::FromArgb(12, 255, 45, 45)
$hazeBottom = [System.Drawing.Color]::FromArgb(0, 255, 45, 45)
$haze = New-Object System.Drawing.Drawing2D.LinearGradientBrush($full, $hazeTop, $hazeBottom, 55.0)
$g.FillRectangle($haze, $full)

# Wordmark, fitted to a fixed optical width.
$targetWordWidth = 700.0
$font = New-Object System.Drawing.Font("Arial Black", 200, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$measure = $g.MeasureString("bycreep", $font)
if ($measure.Width -gt 0) {
    $fontSize = 200.0 * $targetWordWidth / $measure.Width
    $font.Dispose()
    $font = New-Object System.Drawing.Font("Arial Black", $fontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
}
$measure = $g.MeasureString("bycreep", $font)

$dotSize = 24.0
$dotGap = 14.0
$groupWidth = $measure.Width + $dotGap + $dotSize
$wordX = ($size - $groupWidth) / 2.0
$wordY = 250.0

$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$g.DrawString("bycreep", $font, $white, [float]$wordX, [float]$wordY)

$red = [System.Drawing.Color]::FromArgb(255, 255, 45, 45)
$dotBrush = New-Object System.Drawing.SolidBrush($red)
$dotX = $wordX + $measure.Width + $dotGap
$dotY = $wordY + 44.0
$g.FillEllipse($dotBrush, [float]$dotX, [float]$dotY, [float]$dotSize, [float]$dotSize)

# Seven day circles with one glowing red training day.
$count = 7
$diameter = 96.0
$gap = 22.0
$rowWidth = ($count * $diameter) + (($count - 1) * $gap)
$startX = ($size - $rowWidth) / 2.0
$rowY = 572.0
$labels = @(
    "$([char]0x041F)$([char]0x041D)",
    "$([char]0x0412)$([char]0x0422)",
    "$([char]0x0421)$([char]0x0420)",
    "$([char]0x0427)$([char]0x0422)",
    "$([char]0x041F)$([char]0x0422)",
    "$([char]0x0421)$([char]0x0411)",
    "$([char]0x0412)$([char]0x0421)"
)
$labelFont = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 255, 255, 255))
$labelFormat = New-Object System.Drawing.StringFormat
$labelFormat.Alignment = [System.Drawing.StringAlignment]::Center

# Soft red bloom behind the training-day circle. Drawn before every solid
# circle so the glow never tints its white neighbours.
$glowIndex = 3
$glowX = $startX + ($glowIndex * ($diameter + $gap))
for ($glow = 12; $glow -ge 1; $glow--) {
    $spread = $glow * 5.0
    $glowAlpha = [int](7 * (13 - $glow) / 2)
    $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($glowAlpha, 255, 45, 45))
    $glowRect = New-Object System.Drawing.RectangleF(
        [float]($glowX - $spread),
        [float]($rowY - $spread),
        [float]($diameter + ($spread * 2)),
        [float]($diameter + ($spread * 2))
    )
    $g.FillEllipse($glowBrush, $glowRect)
    $glowBrush.Dispose()
}

for ($i = 0; $i -lt $count; $i++) {
    $x = $startX + ($i * ($diameter + $gap))
    $circleRect = New-Object System.Drawing.RectangleF([float]$x, [float]$rowY, [float]$diameter, [float]$diameter)

    if ($i -eq $glowIndex) {
        $redTop = [System.Drawing.Color]::FromArgb(255, 255, 64, 54)
        $redBottom = [System.Drawing.Color]::FromArgb(255, 176, 0, 18)
        $redBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($circleRect, $redTop, $redBottom, 90.0)
        $g.FillEllipse($redBrush, $circleRect)
        $redBrush.Dispose()
    } else {
        $g.FillEllipse($white, $circleRect)
    }

    $labelRect = New-Object System.Drawing.RectangleF(
        [float]($x - 8),
        [float]($rowY + $diameter + 20),
        [float]($diameter + 16),
        40
    )
    $g.DrawString($labels[$i], $labelFont, $labelBrush, $labelRect, $labelFormat)
}

$output = Join-Path $PSScriptRoot "..\bycreep\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon.png"
$resolvedOutput = [System.IO.Path]::GetFullPath($output)
$bmp.Save($resolvedOutput, [System.Drawing.Imaging.ImageFormat]::Png)

$labelFormat.Dispose()
$labelFont.Dispose()
$labelBrush.Dispose()
$dotBrush.Dispose()
$white.Dispose()
$haze.Dispose()
$background.Dispose()
$font.Dispose()
$g.Dispose()
$bmp.Dispose()

Write-Output "Wrote $resolvedOutput"
