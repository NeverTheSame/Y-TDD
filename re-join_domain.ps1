# 1. получил список машин (читаем из CSV)
$vms = Import-Csv -Path ".\gcp_vms.csv"
$credential = Get-Credential -UserName "DOMAIN\Administrator" -Message "Enter Domain Admin credentials"

# 2. исполнил команды на каждой удаленной машине
foreach ($vm in $vms) {
    $session = New-PSSession -ComputerName $vm.networkIP -Credential $credential

    Invoke-Command -Session $session -ScriptBlock {
        param($vmName, $domainName, $newIp, $subnet, $gateway)

        # 1. убрал из старого домена
        Remove-Computer -UnjoinDomain -Credential $using:credential -Force -Restart -WhatIf

        # 2. поменял сетевые настройки
        Get-NetAdapter | Set-NetIPAddress -IPAddress $newIp -PrefixLength $subnet -DefaultGateway $gateway -Confirm:$false

        # 3. добавил в новый домен
        Add-Computer -DomainName $domainName -Credential $using:credential -Restart -Force
    } -ArgumentList $vm.name, "mycompany.corp", $vm.networkIP, 24, "10.10.0.1"

    Remove-PSSession -Session $session
    Write-Host "Finished processing $($vm.name)"
}