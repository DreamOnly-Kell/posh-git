# Hack! https://gist.github.com/lzybkr/f2059cb2ee8d0c13c65ab933b75e998c

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class NativeConsoleMethods
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr GetStdHandle(int handleId);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool GetConsoleMode(IntPtr hConsoleOutput, out uint dwMode);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetConsoleMode(IntPtr hConsoleOutput, uint dwMode);

    public static uint GetConsoleMode(bool input = false)
    {
        var handle = GetStdHandle(input ? -10 : -11);
        uint mode;
        if (GetConsoleMode(handle, out mode))
        {
            return mode;
        }
        return 0xffffffff;
    }

    public static uint SetConsoleMode(bool input, uint mode)
    {
        var handle = GetStdHandle(input ? -10 : -11);
        if (SetConsoleMode(handle, mode))
        {
            return GetConsoleMode(input);
        }
        return 0xffffffff;
    }
}
"@

[Flags()]
enum ConsoleModeInputFlags
{
    ENABLE_PROCESSED_INPUT             = 0x0001
    ENABLE_LINE_INPUT                  = 0x0002
    ENABLE_ECHO_INPUT                  = 0x0004
    ENABLE_WINDOW_INPUT                = 0x0008
    ENABLE_MOUSE_INPUT                 = 0x0010
    ENABLE_INSERT_MODE                 = 0x0020
    ENABLE_QUICK_EDIT_MODE             = 0x0040
    ENABLE_EXTENDED_FLAGS              = 0x0080
    ENABLE_AUTO_POSITION               = 0x0100
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0200
}

[Flags()]
enum ConsoleModeOutputFlags
{
    ENABLE_PROCESSED_OUTPUT            = 0x0001
    ENABLE_WRAP_AT_EOL_OUTPUT          = 0x0002
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
}

function Get-ConsoleMode
{
    [CmdletBinding()]
    param(
        [switch]
        $StandardInput
    )

    $mode = [NativeConsoleMethods]::GetConsoleMode($StandardInput)
    if ($StandardInput)
    {
        [ConsoleModeInputFlags]$mode
    }
    else
    {
        [ConsoleModeOutputFlags]$mode
    }
}

function Set-ConsoleMode
{
    param(
        [Parameter(ParameterSetName = "ANSI")]
        [switch]
        $ANSI,

        [Parameter(ParameterSetName = "Mode")]
        [uint32]
        $Mode,

        [switch]
        $StandardInput
    )

    if ($ANSI)
    {
        $outputMode = [NativeConsoleMethods]::GetConsoleMode($false)
        $null = [NativeConsoleMethods]::SetConsoleMode($false, $outputMode -bor [ConsoleModeOutputFlags]::ENABLE_VIRTUAL_TERMINAL_PROCESSING)

        if ($StandardInput)
        {
            $inputMode = [NativeConsoleMethods]::GetConsoleMode($true)
            $null = [NativeConsoleMethods]::SetConsoleMode($true, $inputMode -bor [ConsoleModeInputFlags]::ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        }
    }
    else
    {
        [NativeConsoleMethods]::SetConsoleMode($StandardInput, $Mode)
    }
}

function Reset-Colors
{
    $mode = [NativeConsoleMethods]::GetConsoleMode()
    Set-ConsoleMode -ANSI
    "$([char]0x1b)[0m"
    [NativeConsoleMethods]::SetConsoleMode($false, $mode)
}
