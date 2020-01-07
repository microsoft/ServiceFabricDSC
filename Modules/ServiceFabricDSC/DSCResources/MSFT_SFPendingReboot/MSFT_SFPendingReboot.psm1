function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName
    )

    Write-Verbose -Message "Getting Information about reboot state for node {$NodeName}"

    $IsInCluster = $false
    try
    {
        Connect-ServiceFabricCluster -ErrorAction Stop
        $IsInCluster = $true
    }
    catch
    {
        Write-Verbose -Message "The current Node {$NodeName} is not joined to a Service Fabric Cluster."
    }
    $result = @{
        NodeName      = $NodeName
        IsInCluster   = $IsInCluster
        PendingReboot = Test-SFPendingReboot
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName
    )

    Write-Verbose -Message "Processing reboot request for Node {$NodeName}"

    $currentValues = Get-TargetResource @PSBoundParameters

    if ($currentValues.PendingReboot -and $currentValues.IsInCluster)
    {
        Write-Verbose -Message "Service Fabric Node {$NodeName} is already in a cluster. `
            Creating a repair job to handle the reboot operation."
        try
        {
            Start-ServiceFabricRepairTask -NodeName $NodeName -NodeAction Reboot
        }
        catch
        {
            throw $_
        }
    }
    elseif ($currentValues.PendingReboot -and -not $currentValues.IsInCluster)
    {
        Write-Verbose -Message "Node {$NodeName} is not joined to a Service Fabric cluster. Forcing Reboot."
        $global:DSCMachineStatus = 1
    }
    else
    {
        Write-Verbose -Message "Node {$NodeName} is not pending a reboot. No action taken."
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $NodeName
    )

    Write-Verbose -Message "Testing to see if Node {$NodeName} needs to be rebooted."

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return !($CurrentValues.PendingReboot)
}

Export-ModuleMember -Function *-TargetResource
