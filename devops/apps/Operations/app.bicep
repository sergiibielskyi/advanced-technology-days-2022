param location string = resourceGroup().location

var cnf = json(loadTextContent('config.json'))
var containerAdmin = cnf.containerAdmin
var containerKey = cnf.containerKey
var accountKey = cnf.secretValueBlob
var cosmosdbUrl = cnf.cosmosDBUrl
var deliveryImagePath = cnf.deliveryImagePath
var resourceGroupName = cnf.resourceGroupName
var environmentName = cnf.environmentName
var environmentId = cnf.environmentId
var storageAccountName = cnf.storageAccountName
var containerRegistry = cnf.containerRegistry
var masterKey = cnf.masterKey
var connectionString = cnf.connectionString

module operationsapp 'operations.bicep' = {
  name: 'operationsapp'
  params: {
    environmentId: environmentId
    location: location
    containerRegistry: containerRegistry
    containerRegistryUsername: containerAdmin
    registrySecretRefName: containerKey
    imagePath: deliveryImagePath
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup(resourceGroupName)
  ]
}

resource checkoutComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/checkout'
  properties: {
    componentType: 'bindings.azure.storagequeues'
    version: 'v1'
    secrets: [
      {
        name: 'account-key'
        value: accountKey
      }
    ]
    metadata: [
      {
        name: 'storageAccount'
        value: storageAccountName
      }
      {
        name: 'storageAccessKey'
        secretRef: 'account-key'
      }
      {
        name: 'queue'
        value: 'orders'
      }
    ]
    scopes: [
      operationsapp.name
    ]
  }
}

resource cosmosDBComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/cosmosdbapp'
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
      {
        name: 'account-key'
        value: masterKey
      }
    ]
    metadata: [
      {
        name: 'url'
        value: cosmosdbUrl
      }
      {
        name: 'masterKey'
        secretRef: 'account-key'
      }
      {
        name: 'database'
        value: 'advtechDB'
      }
      {
        name: 'collection'
        value: 'advtechContainer'
      }
    ]
    scopes: [
      operationsapp.name
    ]
  }
}

resource postgreSQLComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/postgresqlapp'
  properties: {
    componentType: 'state.postgresql'
    version: 'v1'
    secrets: [
      {
        name: 'account-key'
        value: connectionString
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'account-key'
      }
    ]
    scopes: [
      operationsapp.name
    ]
  }
}

