$users = Import-Csv -Path "C:\path"

function Generate-RandomPassword {
    param (
        [int]$length = 12
    )
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
    $password = -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
    return $password
}	


foreach ($user in $users) {
	$password = Generate-RandomPassword
	New-MailUser -Name $user.Name -Alias $user.Alias -ExternalEmailAddress $user.ExternalEmailAddress -MicrosoftOnlineServicesID $user.MicrosoftOnlineServicesID -Password (ConvertTo-SecureString $password -AsPlainText -Force)
	Write-Output "Created user: $($user.Name) with password: $password"
}

