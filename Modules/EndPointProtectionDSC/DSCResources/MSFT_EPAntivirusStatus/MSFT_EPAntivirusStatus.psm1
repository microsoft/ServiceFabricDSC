function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AntivirusName,

        [Parameter()]
        [System.String]
        [ValidateSet("Running", "Stopped")]
        $Status = "Running",

        [Parameter()]
        [System.String]
        [ValidateSet("Absent", "Present")]
        $Ensure
    )

    Write-Verbose -Message "Getting Information about Antivirus {$AntivirusName}"

    $AntivirusInfo = Get-EPDSCInstalledAntivirus -AntivirusName $AntivirusName

    $nullReturn = $PSBoundParameters
    $nullReturn.Ensure = "Absent"
    if ($null -eq $AntivirusInfo)
    {
        Write-Verbose -Message "Could not obtain Information about Antivirus {$AntivirusName}"
        return $nullReturn
    }

    try
    {
        $executablePathParts = $AntivirusInfo.pathToSignedReportingExe.Split("\")
        $executableName = $executablePathParts[$executablePathParts.Length -1].Split('.')[0]
        $process = Get-EPDSCProcessByReportingExecutable -ExecutableName $executableName

        $statusValue = "Running"
        if ($null -eq $process)
        {
            $statusValue = "Stopped"
        }
        $result = @{
            AntivirusName = $AntivirusName
            Status        = $statusValue
            Ensure        = "Present"
        }
    }
    catch
    {
        Write-Verbose -Message "Could not retrieve process runnign for Antivirus {$AntivirusName}"
        return $nullReturn
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
        $AntivirusName,

        [Parameter()]
        [System.String]
        [ValidateSet("Running", "Stopped")]
        $Status = "Running",

        [Parameter()]
        [System.String]
        [ValidateSet("Absent", "Present")]
        $Ensure
    )

    Write-Verbose -Message "Calling the Set-TargetResource function for Antivirus {$AntivirusName}"

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AntivirusName,

        [Parameter()]
        [System.String]
        [ValidateSet("Running", "Stopped")]
        $Status = "Running",

        [Parameter()]
        [System.String]
        [ValidateSet("Absent", "Present")]
        $Ensure
    )

    Write-Verbose -Message "Testing Settings of Antivirus {$AntivirusName}"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $result = $true
    if ($CurrentValues.Status -ne $Status -or $CurrentValues.Ensure -ne $Ensure)
    {
        $result = $false
    }
    Write-Verbose -Message "Test-TargetResource returned $result"
    return $result
}

Export-ModuleMember -Function *-TargetResource
