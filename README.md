# xCertificateStore DSC Resource
This repository contains a custom DSC Resource.

## What?
This DSC Resources enables manipulation of the Certificate Store in Windows. Currently it only supports the LocalMachine root store.

**In its current condition the resource should be viewed as experimental.**

## How?
A simple feature complete example would be something like this.
```PowerShell
Configuration Example_ConfigurationStore
{
    Import-DscResource -Name xCertificateStore

    Node 'localhost' {
        xCertificateStore MakeSureAbsent
        {
            Ensure = "Absent"
            RootStore = "LocalMachine"
            Store = "Root"
            Thumbprint = "CC9535EA3ACBC5350662E02B5D29420ED9BEEC9B"
        }

        xCertificateStore MakeSurePresent
        {
            Ensure = "Present"
            RootStore = "LocalMachine"
            Store = "Root"
            Thumbprint = "6252DC40F71143A22FDE9EF7348E064251B18118"
            Path = "C:\foo\test.cer"
        }

        xCertificateStore PriveKeyWithPassword
        {
            Ensure = "Present"
            RootStore = "LocalMachine"
            Store = "My"
            Thumbprint = "CC9535EA3ACBC5350662E02B5D29420ED9BEEC9B"
            Path = "C:\foo\test.pfx"
            Password = "TestPassword"
        }
    }
}
```

## Todo?
Probably forgot about some edge case. I am happy to accept pull requests

## License?
Yeah, sure, why not.

The resource is licensed under the MIT License, and is made by Torkild Retvedt.
