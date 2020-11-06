<#
    .DESCRIPTION
        A runbook to demonstrate importing API's to an APIM instance

    .NOTES
        AUTHOR: Jim Lane - CSA Manufacturing SOU
        LASTEDIT: Nov 3, 2020
#>

$connectionName = "AzureRunAsConnection"
$apimSvc = Get-AutomationVariable -Name 'apimServiceName'
$rgName = Get-AutomationVariable -Name 'resourceGroupName'
$loc = Get-AutomationVariable -Name 'location' 
$org = Get-AutomationVariable -Name 'organization'
$email = Get-AutomationVariable -Name 'adminEmail'
$swagger = Get-AutomationVariable -Name 'swaggerUrl'
$path = Get-AutomationVariable -Name 'apiPath'
$product = Get-AutomationVariable -Name 'productName'
$description = Get-AutomationVariable -Name 'productDescription'
$state = Get-AutomationVariable -Name 'productState'

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName 

    "Logging in to Azure..."
    Add-AzAccount `
        -ServicePrincipal `
        -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

####################################
# Import API
####################################
try{
    # Create the API Management context
    $context = New-AzApiManagementContext -ResourceGroupName $rgName -ServiceName $apimSvc

    # Create initial version
    $versionSet = New-AzApiManagementApiVersionSet -Context $context -Name "Petstore API" -Scheme Segment -Description "version set sample"

    # import api from Url and assign to initial version
    Write-Output ("Importing API")
    $api = Import-AzApiManagementApi -Context $context -SpecificationUrl $swagger -SpecificationFormat Swagger -Path $path -ApiVersionSetId $versionSet.ApiVersionSetId

    # Create a Product to publish the Imported Api. This creates a product with a limit of 10 Subscriptions
    Write-Output ("Creating product")
    $product = New-AzApiManagementProduct -Context $context -Title $product -Description $description -State $state -SubscriptionsLimit 10 

    # Add the petstore api to the published Product, so that it can be called in developer portal console
    Write-Output ("Adding API to product")
    Add-AzApiManagementApiToProduct -Context $context -ProductId $product.ProductId -ApiId $api.ApiId

    # import api from Url and assign to new api version
    Write-Output ("Creating new version")
    $version = Import-AzApiManagementApi -Context $context -SpecificationUrl $swagger -SpecificationFormat Swagger -Path "newPetStore" -ApiVersionSetId $versionSet.ApiVersionSetId -ApiVersion V2

    # Get reference to desired API verion and create a new revision
    Write-Output ("Creating new revision")
    New-AzApiManagementApiRevision -Context $context -ApiId $api.ApiId -ApiRevision "2" -ApiRevisionDescription "New Bugfix" -SourceApiRevision "1" -ServiceUrl $swagger
}
catch{
    Write-Error ("API import failed: " + $_)
}
if ($res)
{
    Write-Output ("API successfully imported")
}
