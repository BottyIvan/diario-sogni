$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$appRoot = Split-Path $PSScriptRoot -Parent
$targets = @{
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' = 48
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' = 72
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' = 96
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' = 144
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' = 192
  'web/icons/Icon-192.png' = 192
  'web/icons/Icon-512.png' = 512
  'web/icons/Icon-maskable-192.png' = 192
  'web/icons/Icon-maskable-512.png' = 512
  'web/favicon.png' = 64
}
foreach ($target in $targets.GetEnumerator()) {
  $size = $target.Value
  $bitmap = [System.Drawing.Bitmap]::new($size, $size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $background = [System.Drawing.ColorTranslator]::FromHtml('#342B48')
  $graphics.Clear($background)
  $gold = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#F1D7AB'))
  $cover = [System.Drawing.SolidBrush]::new($background)
  $graphics.FillEllipse($gold, [single]($size*.25), [single]($size*.22), [single]($size*.48), [single]($size*.56))
  $graphics.FillEllipse($cover, [single]($size*.40), [single]($size*.16), [single]($size*.40), [single]($size*.48))
  $graphics.FillEllipse($gold, [single]($size*.68), [single]($size*.27), [single]($size*.055), [single]($size*.055))
  $graphics.FillEllipse($gold, [single]($size*.75), [single]($size*.47), [single]($size*.035), [single]($size*.035))
  $bitmap.Save((Join-Path $appRoot $target.Key), [System.Drawing.Imaging.ImageFormat]::Png)
  $gold.Dispose(); $cover.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
