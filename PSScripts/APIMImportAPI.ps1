##########################################################
#  Script to import an API and add it to a Product in api Management 
#  Adding the Imported api to a product is necessary, so that it can be called by a subscription
########################################################### 

#Login-AzAccount
$random = (New-Guid).ToString().Substring(0,8)

#Azure specific details
$subscriptionId = "837b99dc-6522-41f7-a6e5-e1d1a7af02e9"

# Api Management service specific details
$apimServiceName = "apim-b85c301f"
$resourceGroupName = "APIMDemos"
$location = "East US 2"
$organisation = "Contoso"
$adminEmail = "jimlane@microsoft.com"

# Api Specific Details
$swaggerUrl = "http://petstore.swagger.io/v2/swagger.json"
$apiPath = "petstore"

# Set the context to the subscription Id where the cluster will be created
Select-AzSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# Create the API Management context
$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName

# Create initial version
$versionSet = New-AzApiManagementApiVersionSet -Context $context -Name "Petstore API" -Scheme Segment -Description "version set sample"

# import api from Url and assign to initial version
$api = Import-AzApiManagementApi -Context $context -SpecificationUrl $swaggerUrl -SpecificationFormat Swagger -Path $apiPath -ApiVersionSetId $versionSet.ApiVersionSetId

$productName = "Pet Store Product"
$productDescription = "Product giving access to Petstore api"
$productState = "Published"

# Create a Product to publish the Imported Api. This creates a product with a limit of 10 Subscriptions
$product = New-AzApiManagementProduct -Context $context -Title $productName -Description $productDescription -State $productState -SubscriptionsLimit 10 

# Add the petstore api to the published Product, so that it can be called in developer portal console
Add-AzApiManagementApiToProduct -Context $context -ProductId $product.ProductId -ApiId $api.ApiId

# import api from Url and assign to new api version
$version = Import-AzApiManagementApi -Context $context -SpecificationUrl $swaggerUrl -SpecificationFormat Swagger -Path "newPetStore" -ApiVersionSetId $versionSet.ApiVersionSetId -ApiVersion V2

# Get reference to desired API verion and create a new revision
New-AzApiManagementApiRevision -Context $context -ApiId $api.ApiId -ApiRevision "2" -ApiRevisionDescription "New Bugfix" -SourceApiRevision "1" -ServiceUrl $swaggerUrl
