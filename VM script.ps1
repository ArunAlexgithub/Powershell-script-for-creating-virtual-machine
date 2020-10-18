cls
[string]$vmName= Read-Host ”Name of VM”

[int32]$generation = Read-Host "Generation Type"

[string]$dynamic = $null
while("yes","no" -notcontains $dynamic){
    $dynamic = Read-Host "Will this VM use dyanmic memory? (yes/no)"
}
if($dynamic -eq "yes"){
    [bool]$dynMemory = $true
    [int64]$minMemory = Read-Host "Memory Minimum (MB)"
    [int64]$maxMemory = Read-Host "Memory Maximum (MB)"
    [int64]$startMemory = Read-Host "Starting Memory (MB)"
  
    $minMemory = 1MB*$minMemory
    $maxMemory = 1MB*$maxMemory
    $startMemory = 1MB*$startMemory
    [int64]$memory = $minMemory
}
else{
    [int64]$memory = Read-Host "Memory (MB)"

    $memory = 1MB*$memory
}

Write-Host "--------AVAILABLE SWITCHES--------" -BackgroundColor Red
Get-VMSwitch | Select-Object -ExpandProperty Name
Write-Host "-------- SWITCHES--------" -BackgroundColor Red
[string]$vmSwitch = Read-Host "Please enter a virtual switch name"

[int32]$cpu = Read-Host "Number of CPUs"

[string]$vmPath = Read-Host "Enter path for VM "
[string]$newVMPath = $vmPath

[string]$vhdPath = Read-Host "Enter path where .vhdx will reside "
[string]$newVHD = $vhdPath+$VMName+".vhdx"
[int64]$vhdSize = Read-Host "Enter VHDSize (GB)"
$vhdSize = [math]::round($vhdSize *1Gb, 3) 
$isopath= Read-Host "Enter iso image path"
 
try{
   
    Write-Host "Creating new VM:" $vmName "Generation type:" $generation `
        "Starting memory:" $memory "stored at:" $newVMPath ", `
            with its .vhdx stored at:" $newVHD "(size" $vhdSize ")" -ForegroundColor DarkBlue
    [string]$confirm = $null
    while("yes","no" -notcontains $confirm){
        $confirm = Read-Host "Proceed? (yes/no)"
    }
   
    if($confirm -eq "yes"){
      
        NEW-VM –Name $vmName -Generation $generation –MemoryStartupBytes $memory `
            -Path $newVMPath –NewVHDPath $newVHD –NewVHDSizeBytes $vhdSize | Out-Null
        Start-Sleep 5
        ADD-VMNetworkAdapter –VMName $vmName –Switchname $vmSwitch
        Add-VMDvdDrive -VMName $VMName -Path $isopath

        
        Set-VMProcessor –VMName $vmName –count $cpu
      
        if($dynMemory -eq $true){
            Set-VMMemory $vmName -DynamicMemoryEnabled $true -MinimumBytes $minMemory `
                -StartupBytes $startMemory -MaximumBytes $maxMemory
        }
        Start-Sleep 8 
        Get-VM -Name $vmName | Select Name,State,Generation,ProcessorCount,`
            @{Label=”MemoryStartup”;Expression={($_.MemoryStartup/1MB)}},`
            @{Label="MemoryMinimum";Expression={($_.MemoryMinimum/1MB)}},`
            @{Label="MemoryMaximum";Expression={($_.MemoryMaximum/1MB)}} `
            ,Path,Status | ft -AutoSize
        Start-VM -name $vmName
        vmconnect localhost $vmName
         localhost $vmName
    }
    else{
        Exit
    }
    
}
catch{
    Write-Host "An error was encountered creating the new VM" `
        -ForegroundColor Red -BackgroundColor Black
    Write-Error $_
}