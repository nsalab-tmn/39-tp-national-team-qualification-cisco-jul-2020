$cifile = "C:\Users\lawliet\YandexDisk\Deploy\cloud-init.yml"
$CData = $CData = get-content $cifile | Out-String
for($i = 1; $i -lt 44 ; $i++){
Start-Job -FilePath deployscript.ps1 -ArgumentList "MODC-RG","EVE","centralus","Standard_D4s_v3",$CData
}
