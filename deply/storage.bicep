param location string = resourceGroup().location
param storageAccountNamePrefix string = 'mystorage'
param skuName string = 'Standard_LRS'
param storageContainerName string = 'container'

var kind = 'StorageV2'
var storageAccountName = '${toLower(take(storageAccountNamePrefix, 11))}${uniqueString(resourceGroup().id)}' //24文字以下にする

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {}
}
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: storageContainerName
}

output storageAccountName string = storageAccount.name
