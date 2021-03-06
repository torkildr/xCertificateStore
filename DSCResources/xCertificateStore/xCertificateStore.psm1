function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [parameter(Mandatory = $true)]
        [ValidateSet("LocalMachine")]
        [System.String]
        $RootStore,

        [parameter(Mandatory = $true)]
        [ValidateSet("TrustedPublisher","ClientAuthIssuer","LyncCertStore","Remote Desktop","Root","TrustedDevices","MSIEHistoryJournal","CA","Windows Live ID Token Issuer","Request","AuthRoot","FlightRoot","TrustedPeople","My","SmartCardRoot","Trust","Disallowed")]
        [System.String]
        $Store
    )

    $returnValue = @{
        Ensure = [System.String] "Absent"
        Thumbprint = [System.String] $Thumbprint
        RootStore = [System.String] $RootStore
        Store = [System.String] $Store
        Expires = [System.DateTime]
        Subject = [System.String] $null
    }

    $CertificatePath = Join-Path (Join-Path (Join-Path "cert:" $RootStore) $Store) $Thumbprint
    
    Write-Verbose "Checking for certificiate: $CertificatePath"
    
    if (Test-Path $CertificatePath)
    {
        $cert = Get-item $CertificatePath

        $returnValue.Ensure = "Present"
        $returnValue.Expires = $cert.NotAfter
        $returnValue.Subject = $cert.Subject

        Write-Verbose ("Certificate is present. Subject: {0}, Expires: {1}" -f $returnValue.Subject, $returnValue.Expires)
    }
    else
    {
        Write-Verbose "Certificate is absent"
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [parameter(Mandatory = $true)]
        [ValidateSet("LocalMachine")]
        [System.String]
        $RootStore,

        [parameter(Mandatory = $true)]
        [ValidateSet("TrustedPublisher","ClientAuthIssuer","LyncCertStore","Remote Desktop","Root","TrustedDevices","MSIEHistoryJournal","CA","Windows Live ID Token Issuer","Request","AuthRoot","FlightRoot","TrustedPeople","My","SmartCardRoot","Trust","Disallowed")]
        [System.String]
        $Store,

        [System.String]
        $Path,

        [System.String]
        $Password
    )
    
    $CertificatePath = Join-Path (Join-Path (Join-Path "cert:" $RootStore) $Store) $Thumbprint
    Write-Verbose "Fixing so that the certificate $CertificatePath is $Ensure"

    # Install certificate
    if ($Ensure -eq "Present")
    {
        if ([System.String]::IsNullOrWhiteSpace($Path))
        {
            throw "No certificate path given"
        }

        if (-not (Test-Path $Path))
        {
            throw "Invalid certificate path: $Path"
        }

        Write-Verbose "Importing certificate from $Path"

        $x509cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
        
        if (-not [System.String]::IsNullOrEmpty($Password))
        {
            $x509cert.Import($Path, $Password, "PersistKeySet,Exportable")
        }
        else
        {
            $x509cert.Import($Path)

            if ([System.String]::IsNullOrWhiteSpace($x509cert.Thumbprint))
            {
                throw "Could not import certificate. Maybe it is password protected?"
            }
        }

        if ($x509cert.Thumbprint -ne $Thumbprint)
        {
            throw ("Thumbprint of imported certificate {0} does not match that of the expected {1}" -f $x509cert.Thumbprint, $Thumbprint)
        }
        
        $certStore = New-Object System.Security.Cryptography.X509Certificates.X509Store($Store, $RootStore)
        $certStore.Open("ReadWrite")
        $certStore.Add($x509cert)
        $certStore.Close()
    }
    # Remove certificate
    else
    {
        if (Test-Path $CertificatePath)
        {
            Write-Verbose "Removing $CertificatePath"
            Remove-Item $CertificatePath
        }
        else
        {
            Write-Verbose "$CertificatePath has already been removed"
        }
    }

    # Fail loudly if something went wrong
    if ($Ensure -eq "Present" -and -not (Test-Path $CertificatePath))
    {
        throw "Failed to add certificate $CertificatePath"
    }
    elseif ($Ensure -eq "Absent" -and (Test-Path $CertificatePath))
    {
        throw "Failed to remove certificate $CertificatePath"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [parameter(Mandatory = $true)]
        [ValidateSet("LocalMachine")]
        [System.String]
        $RootStore,

        [parameter(Mandatory = $true)]
        [ValidateSet("TrustedPublisher","ClientAuthIssuer","LyncCertStore","Remote Desktop","Root","TrustedDevices","MSIEHistoryJournal","CA","Windows Live ID Token Issuer","Request","AuthRoot","FlightRoot","TrustedPeople","My","SmartCardRoot","Trust","Disallowed")]
        [System.String]
        $Store,

        [System.String]
        $Path,

        [System.String]
        $Password
    )
    
    $certificate = Get-TargetResource -RootStore $RootStore -Store $Store -Thumbprint $Thumbprint

    if (($Ensure -eq "Present" -and $certificate.Ensure -eq "Present") -or ($Ensure -eq "Absent" -and $certificate.Ensure -eq "Absent"))
    {
        $true
    }
    else
    {
        $false
    }
}

Export-ModuleMember -Function *-TargetResource
