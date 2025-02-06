@description('リソースのリージョン')
param location string = resourceGroup().location

@description('Storage Account の名前（グローバルで一意）')
param storageAccountNamePrefix string = 'storage'

param storageAccountContainer string = 'cont'

@description('App Service プラン名')
param appServicePlanName string = 'AppServicePlan'

@description('Web App の名前（グローバルで一意）')
param webAppNamePrefix string = 'webapplin'

// Storage Account のモジュールを呼び出す
module storageModule './storage.bicep' = {
  name: 'deployStorage'
  params: {
    location: location
    storageAccountNamePrefix: storageAccountNamePrefix
  }
}

// App Service のモジュール呼び出し
module appServiceModule './appservice.bicep' = {
  name: 'deployAppService'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppNamePrefix: webAppNamePrefix
    linuxFxVersion: 'PYTHON|3.11'
    storageAccountName: storageModule.outputs.storageAccountName
    storageContainerName: storageAccountContainer
  }
}

output storageAccountName string = storageModule.outputs.storageAccountName
output webAppUrl string = appServiceModule.outputs.webAppUrl
output webAppName string = appServiceModule.outputs.webAppName
