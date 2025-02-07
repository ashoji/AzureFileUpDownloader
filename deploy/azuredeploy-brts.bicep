@description('リソースのリージョン')
param location string = resourceGroup().location

@description('Storage Account の名前（グローバルで一意）')
param storageAccountNamePrefix string = 'storage'

param storageAccountContainer string = 'container'

@description('App Service プラン名')
param appServicePlanName string = 'AppServicePlan'

@description('Web App の名前（グローバルで一意）')
param webAppName string = 'webapplin-4dcnaw7p7euem'

// Storage Account のモジュールを呼び出す
// module storageModule './storage.bicep' = {
// Template Speck
module storageModule 'ts/CoreSpecs:Storage:1.1' = {
name: 'deployStorage'
  params: {
    location: location
    storageContainerName: storageAccountContainer
    storageAccountNamePrefix: storageAccountNamePrefix
  }
}

// App Service のモジュール呼び出し
// module appServiceModule './appservice.bicep' = {
module appServiceModule 'br/CoreModules:appservice:v1' = {
name: 'deployAppService'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    linuxFxVersion: 'PYTHON|3.11'
    storageAccountName: storageModule.outputs.storageAccountName
    storageContainerName: storageAccountContainer
  }
}

output storageAccountName string = storageModule.outputs.storageAccountName
output webAppUrl string = appServiceModule.outputs.webAppUrl
