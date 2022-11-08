param location string = resourceGroup().location

var cnf = json(loadTextContent('config.json'))
var containerAdmin = cnf.containerAdmin
var containerKey = cnf.containerKey
var accountKey = cnf.secretValueBlob
var deliveryImagePath = cnf.deliveryImagePath
var resourceGroupName = cnf.resourceGroupName
var environmentName = cnf.environmentName
var environmentId = cnf.environmentId
var storageAccountName = cnf.storageAccountName
var containerRegistry = cnf.containerRegistry

module deliveryapp 'delivery.bicep' = {
  name: 'deliveryapp'
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

resource blobComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/uploadblobapp'
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    secrets: [
      {
        name: 'account-key'
        value: accountKey
      }
    ]
    metadata: [
      {
        name: 'accountName'
        value: storageAccountName
      }
      {
        name: 'accountKey'
        secretRef: 'account-key'
      }
      {
        name: 'containerName'
        value: 'advtechcontainerblob'
      }
    ]
    scopes: [
      deliveryapp.name
    ]
  }
}


resource queueComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${environmentName}/process-order'
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
      {
        name: 'ttlInSeconds'
        value: '60'
      }
      {
        name: 'decodeBase64'
        value: 'false'
      }
    ]
    scopes: [
      deliveryapp.name
    ]
  }
}

