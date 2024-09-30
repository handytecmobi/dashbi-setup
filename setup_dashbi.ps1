# Función para mostrar el logo
function Show-Logo {
    Write-Output "===================="
    Write-Output "     DASH.BI        "
    Write-Output "===================="
}

# Función para mostrar el progreso
function Show-Progress {
    param (
        [string]$Mensaje
    )
    Write-Output $Mensaje
    Start-Sleep -Seconds 2
}

# Función para crear un grupo de seguridad
function New-Group {
    param (
        [string]$GroupName
    )
    Show-Progress "Creando grupo de seguridad: $GroupName"
    $group = New-AzADGroup -DisplayName $GroupName -MailNickname $GroupName
    return $group
}

# Función para crear una app registration y su secreto
function New-App {
    param (
        [string]$AppName
    )
    Show-Progress "Creando app registration: $AppName"
    $app = New-AzADApplication -DisplayName $AppName
    $servicePrincipal = New-AzADServicePrincipal -ApplicationId $app.AppId
    return [PSCustomObject]@{
        AppName = $AppName
        AppId = $app.AppId
        ObjectId = $servicePrincipal.Id
        AppObjectId = $app.Id
        TenantId = (Get-AzContext).Tenant.Id
    }
}

# Función para agregar una app a un grupo de seguridad
function Add-App-To-Group {
    param (
        [string]$AppId,
        [string]$GrupoId
    )
    Show-Progress "Agregando app $AppId al grupo $GrupoId"
    Add-AzADGroupMember -TargetGroupObjectId $GrupoId -MemberObjectId $AppId
}

# Mostrar el logo
Show-Logo

# Autenticar en Microsoft Entra ID usando autenticación mediante dispositivo
Connect-AzAccount

# Crear los grupos de seguridad
$grupoUsuarios = New-Group -GroupName "DashBIEntraIDUsers"
$grupoPowerBI = New-Group -GroupName "DashBIPowerBIE"
$grupoScanBI = New-Group -GroupName "DashBIScanPBIE"

# Crear las aplicaciones y sus secretos
$appSync = New-App -AppName "app-dashbi-entraid"
Add-AzADAppPermission -ObjectId $appSync.AppObjectId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId 5b567255-7703-4780-807c-7be8301ae99b -Type Role  #Group.Read.All
Add-AzADAppPermission -ObjectId $appSync.AppObjectId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId 98830695-27a2-44f7-8c18-0c3ebc9698f6 -Type Role  #GroupMember.Read.All
Add-AzADAppPermission -ObjectId $appSync.AppObjectId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId 37f7f235-527c-4136-accd-4a02d197296e -Type Scope #openid
Add-AzADAppPermission -ObjectId $appSync.AppObjectId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId 14dad69e-099b-42c9-810b-d002981feec1 -Type Scope #profile
Add-AzADAppPermission -ObjectId $appSync.AppObjectId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId e1fe6dd8-ba31-4d61-89e7-88639da4683d -Type Scope #User.Read 
Add-AzADAppPermission -ObjectId $appSync.AppObjectId -ApiId 00000003-0000-0000-c000-000000000000 -PermissionId df021288-bdef-4463-88db-98f22de89214 -Type Role  #User.Read.All

$appPowerBI = New-App -AppName "app-dashbi-powerbie"
Add-AzADAppPermission -ObjectId $appPowerBI.AppObjectId -ApiId 00000009-0000-0000-c000-000000000000 -PermissionId 8b01a991-5a5a-47f8-91a2-84d6bfd72c02 -Type Scope #App.Read.All
Add-AzADAppPermission -ObjectId $appPowerBI.AppObjectId -ApiId 00000009-0000-0000-c000-000000000000 -PermissionId 7f33e027-4039-419b-938e-2f8ca153e68e -Type Scope #Dataset.Read.All
Add-AzADAppPermission -ObjectId $appPowerBI.AppObjectId -ApiId 00000009-0000-0000-c000-000000000000 -PermissionId 4ae1bf56-f562-4747-b7bc-2fa0874ed46f -Type Scope #Report.Read.All
Add-AzADAppPermission -ObjectId $appPowerBI.AppObjectId -ApiId 00000009-0000-0000-c000-000000000000 -PermissionId 01944dba-21df-426f-bb8c-796488be96ad -Type Scope #Tenant.Read.All
Add-AzADAppPermission -ObjectId $appPowerBI.AppObjectId -ApiId 00000009-0000-0000-c000-000000000000 -PermissionId 654b31ae-d941-4e22-8798-7add8fdf049f -Type Role  #Tenant.Read.All 
Add-AzADAppPermission -ObjectId $appPowerBI.AppObjectId -ApiId 00000009-0000-0000-c000-000000000000 -PermissionId b2f1b2fa-f35c-407c-979c-a858a808ba85 -Type Scope #Workspace.Read.All

$appScanBI = New-App -AppName "app-dashbi-scanpbie"

# Agregar las aplicaciones a los grupos de seguridad correspondientes
Add-App-To-Group -AppId $appPowerBI.ObjectId -GrupoId $grupoPowerBI.Id
Add-App-To-Group -AppId $appScanBI.ObjectId -GrupoId $grupoScanBI.Id

# Retornar una tabla con la información de las aplicaciones
$table = @($appSync, $appPowerBI, $appScanBI)
$table | Format-Table -Property AppName, AppId, TenantId