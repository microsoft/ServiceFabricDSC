function Test-SFPendingReboot
{
    # The list of registry keys that will be used to determine if a reboot is required
    $rebootRegistryKeys = @{
        ComponentBasedServicing = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\'
        WindowsUpdate           = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\'
        PendingFileRename       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\'
        ActiveComputerName      = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'
        PendingComputerName     = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'
    }

    $componentBasedServicingKeys = (Get-ChildItem -Path $rebootRegistryKeys.ComponentBasedServicing).Name

    if ($componentBasedServicingKeys)
    {
        $componentBasedServicing = $componentBasedServicingKeys.Split('\') -contains 'RebootPending'
    }
    else
    {
        $componentBasedServicing = $false
    }

    $windowsUpdateKeys = (Get-ChildItem -Path $rebootRegistryKeys.WindowsUpdate).Name

    if ($windowsUpdateKeys)
    {
        $windowsUpdate = $windowsUpdateKeys.Split('\') -contains 'RebootRequired'
    }
    else
    {
        $windowsUpdate = $false
    }

    $pendingFileRename = (Get-ItemProperty -Path $rebootRegistryKeys.PendingFileRename).PendingFileRenameOperations.Length -gt 0
    $activeComputerName = (Get-ItemProperty -Path $rebootRegistryKeys.ActiveComputerName).ComputerName
    $pendingComputerName = (Get-ItemProperty -Path $rebootRegistryKeys.PendingComputerName).ComputerName
    $pendingComputerRename = $activeComputerName -ne $pendingComputerName

    if ($SkipCcmClientSDK)
    {
        $ccmClientSDK = $false
    }
    else
    {
        $invokeCimMethodParameters = @{
            NameSpace   = 'ROOT\ccm\ClientSDK'
            ClassName   = 'CCM_ClientUtilities'
            Name        = 'DetermineIfRebootPending'
            ErrorAction = 'Stop'
        }

        try
        {
            $ccmClientSDK = Invoke-CimMethod @invokeCimMethodParameters
        }
        catch
        {
            Write-Warning -Message ($script:localizedData.QueryCcmClientUtilitiesFailedMessage -f $_)
        }

        $ccmClientSDK = ($ccmClientSDK.ReturnValue -eq 0) -and ($ccmClientSDK.IsHardRebootPending -or $ccmClientSDK.RebootPending)
    }

    $results = @{
        SkipComponentBasedServicing = $SkipComponentBasedServicing
        ComponentBasedServicing     = $componentBasedServicing
        SkipWindowsUpdate           = $SkipWindowsUpdate
        WindowsUpdate               = $windowsUpdate
        SkipPendingFileRename       = $SkipPendingFileRename
        PendingFileRename           = $pendingFileRename
        SkipPendingComputerRename   = $SkipPendingComputerRename
        PendingComputerRename       = $pendingComputerRename
        SkipCcmClientSDK            = $SkipCcmClientSDK
        CcmClientSDK                = $ccmClientSDK
    }

    $rebootRequired = $false

    foreach ($rebootTrigger in $results)
    {
        $skipTriggerName = 'Skip{0}' -f $rebootTrigger.Name
        $skipTrigger = $pendingRebootState.$skipTriggerName

        if ($skipTrigger)
        {
            Write-Verbose -Message "Reboot Skipped"
        }
        else
        {
            if ($pendingRebootState.$($rebootTrigger.Name))
            {
                Write-Verbose -Message "Reboot pending due to {$($rebootTrigger.Name)}"
                $rebootRequired = $true
            }
        }
    }

    $pendingRebootState += @{
        RebootRequired = $rebootRequired
    }

    return $pendingRebootState
}
