##############################################################
#
#   Script to Get computers from AD based on Physical/Virtual
# 
##############################################################


# Functions

Function Get-MachineType
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
    (
        # ComputerName
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Checking $Computer"
            try {
                # Check to see if $Computer resolves DNS lookup successfuly.
                $null = [System.Net.DNS]::GetHostEntry($Computer)
                
                $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer -ErrorAction Stop -Credential $Credential
                
                switch ($ComputerSystemInfo.Model) {
                    
                    # Check for Hyper-V Machine Type
                    "Virtual Machine" {
                        $MachineType="VM"
                        }

                    # Check for VMware Machine Type
                    "VMware Virtual Platform" {
                        $MachineType="VM"
                        }

                    # Check for Oracle VM Machine Type
                    "VirtualBox" {
                        $MachineType="VM"
                        }

                    # Check for Xen
                    "HVM domU" {
                        $MachineType="VM"
                        }

                    # Check for KVM
                    # I need the values for the Model for which to check.

                    # Otherwise it is a physical Box
                    default {
                        $MachineType="Physical"
                        }
                    }
                
                # Building MachineTypeInfo Object
                $MachineTypeInfo = New-Object -TypeName PSObject -Property ([ordered]@{
                    ComputerName=$ComputerSystemInfo.PSComputername
                    Type=$MachineType
                    Manufacturer=$ComputerSystemInfo.Manufacturer
                    Model=$ComputerSystemInfo.Model
                    })
                $MachineTypeInfo
                }
            catch [Exception] {
                Write-Output "$Computer`: $($_.Exception.Message)"
                }
            }
    }
    End
    {

    }
}

# Variables

#    $OU = 'OU=All Kindred Member Servers,OU=Kindred,DC=ad,DC=mioint,DC=com'
#    $myfilter = "OperatingSystem -Like '*Windows Server*'"
    $OU = 'OU=All Unibet Member Servers,OU=Unibet,DC=unibet,DC=com'
    $myfilter = "OperatingSystem -Like '*Windows Server*' -and Enabled -eq 'True'"

#######


    $computers = Get-ADComputer -Filter $myfilter -Properties Name,ipv4Address,OperatingSystem -SearchBase $OU
    $virtuals = 0
    $Physicals = 0
    $Unknowns = 0

    foreach ($machine in $computers) {

        $computername = $machine.Name
        $Machinetype = Get-MachineType -ComputerName $computername
        $OS = $machine.OperatingSystem
        $type = $Machinetype.Type
        $Manufacturer = $Machinetype.Manufacturer
        $IP = $machine.IPv4Address
        Write-Output "$computername, $OS, $type, $IP"
        if ($Machinetype.type -eq "Physical") { $Physicals++}
        elseif ($Machinetype.type -eq "VM") {$virtuals++}
        else {$Unknowns++}

    }

    Write-Output "Virtual Machines: $virtuals"
    Write-Output "Physical Machines: $Physicals"
    Write-Output "Unknown Machines: $Unknowns"
