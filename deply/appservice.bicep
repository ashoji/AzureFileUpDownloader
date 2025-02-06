param location string = resourceGroup().location
param appServicePlanName string = 'AppServicePlan'
param webAppNamePrefix string = 'WebApp'
param storageAccountName string
param storageContainerName string = 'container'
param linuxFxVersion string = 'PYTHON|3.11'
param appServiceSku string = 'B1'
param appServiceSkuTier string = 'Basic'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServiceSku
    tier: appServiceSkuTier
    capacity: 1
  }
  properties: {
    reserved: true // Linux ベース
  }
}

var webAppName = '${webAppNamePrefix}-${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

var storageAccountKey = storageAccount.listKeys().keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=core.windows.net'

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'AZURE_CONTAINER_NAME'
          value: storageContainerName
        }
        // GitHub Actions 用: ZIP デプロイでパッケージから実行
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        // 他の設定を必要に応じ追加
      ]
    }
  }
}

output webAppUrl string = webApp.properties.defaultHostName
// 追加: Bicep で作成した WebApp の名前を出力
output webAppName string = webAppName
