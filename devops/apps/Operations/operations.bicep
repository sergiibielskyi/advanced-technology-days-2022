param location string = resourceGroup().location
param environmentId string
param containerRegistry string
param containerRegistryUsername string
param imagePath string

@secure()
param registrySecretRefName string

resource operationsapp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'operationsapp'
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      registries: [
        {
          server: containerRegistry
          username: containerRegistryUsername
          passwordSecretRef: 'registry-key'
        }
      ]
      secrets: [
        {
          name: 'registry-key'
          value: registrySecretRefName
        }
      ]
      dapr: {
        enabled: true
        appPort: 80
        appId: 'operationsapp'
      }
    }
    template: {
      containers: [
        {
          image: imagePath
          name: 'operations'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
