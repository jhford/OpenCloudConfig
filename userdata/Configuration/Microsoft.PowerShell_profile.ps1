
# show file extensions in explorer
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type 'DWord' -Name 'HideFileExt' -Value '0x00000002' # off
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type 'DWord' -Name 'Hidden' -Value '0x00000001'
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type 'DWord' -Name 'ShowSuperHidden' -Value '0x00000001'

# a large console, with a large screen buffer (for reading build logs)
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'QuickEdit' -Value '0x00000001' # on
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'InsertMode' -Value '0x00000001' # on
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'ScreenBufferSize' -Value '0x0bb800a0' # 160x3000
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'WindowSize' -Value '0x003c00a0' # 160x60
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'HistoryBufferSize' -Value '0x000003e7' # 999 (max)
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'ScreenColors' -Value '0x0000000a' # green on black
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'FontSize' -Value '0x000c0000' # 12
Set-ItemProperty 'HKCU:\Console\' -Type 'DWord' -Name 'FontFamily' -Value '0x00000036' # default console fonts
Set-ItemProperty 'HKCU:\Console\' -Type 'String' -Name 'FaceName' -Value 'Lucida Console'

# a visible cursor on dark backgrounds (as well as light)
Set-ItemProperty 'HKCU:\Control Panel\Cursors\' -Type 'String' -Name 'IBeam' -Value '%SYSTEMROOT%\Cursors\beam_r.cur'

# powershell, cmd and subl pinned to taskbar
((New-Object -c Shell.Application).Namespace('{0}\System32\WindowsPowerShell\v1.0' -f $env:SystemRoot).parsename('powershell.exe')).InvokeVerb('taskbarpin')
((New-Object -c Shell.Application).Namespace('{0}\System32' -f $env:SystemRoot).parsename('cmd.exe')).InvokeVerb('taskbarpin')
((New-Object -c Shell.Application).Namespace('{0}\System32' -f $env:SystemRoot).parsename('eventvwr.msc')).InvokeVerb('taskbarpin')
((New-Object -c Shell.Application).Namespace('{0}\Sublime Text 3' -f $env:ProgramFiles).parsename('sublime_text.exe')).InvokeVerb('taskbarpin')

$md = @'
[DllImport("user32.dll")]
public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

[DllImport("user32.dll")]
public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetLayeredWindowAttributes(IntPtr hWnd, uint crKey, int bAlpha, uint dwFlags);
'@
if ((Get-ItemProperty -Path ('{0}\System32\hal.dll' -f $env:SystemRoot)).VersionInfo.FileVersion.Split('.')[0] -ne '10') { # Windows versions other than 10
  # transparent powershell and cmd windows
  $user32 = Add-Type -Name 'User32' -Namespace 'Win32' -PassThru -MemberDefinition $md
  Get-Process | Where-Object { @('powershell', 'cmd') -contains $_.ProcessName } | % {
    $user32::SetWindowLong($_.MainWindowHandle, -20, ($user32::GetWindowLong($_.MainWindowHandle, -20) -bor 0x80000)) | Out-Null
    $user32::SetLayeredWindowAttributes($_.MainWindowHandle, 0, 200, 0x02) | Out-Null
  }
}
