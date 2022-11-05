param environmentName string = '@environmentName'
param logAnalyticsWorkspaceName string = '@logAnalyticsWorkspaceName'
param appInsightsName string = 'appins-${environmentName}'
param location string = resourceGroup().location
param accountName string = '@accountName'
param primaryRegion string = resourceGroup().location
param defaultConsistencyLevel string = 'Session'
param databaseName string = '@databaseName'
param containerName string = '@containerName'
param autoscaleMaxThroughput int = 4000
param maxStalenessPrefix int = 100
param maxIntervalInSeconds int = 5
param acrName string = '@acrName'
param acrSku string = 'Basic'
param storageAccountName string = '@storageAccountName'
param containerBlobName string = '@containerBlobName'
param keyVaultName string = '@keyVaultName'
param enabledForDeployment bool = false
param enabledForDiskEncryption bool = false
param enabledForTemplateDeployment bool = false
param tenantId string = subscription().tenantId
param objectId string = '@objectId'
param secretNameCosmosDB string = 'cosmosdb-masterKey'
param secretNameBlob string = 'blob-masterKey'
param serverName string = '@serverName'
param administratorLogin string = '@administratorLogin'
@secure()
param administratorLoginPassword string = '@administratorLoginPassword'
param skuCapacity int = 2
param sku string = 'GP_Gen5_2'
param skuSizeMB int = 51200
param skuTier string = 'GeneralPurpose'
param skuFamily string = 'Gen5'
param postgresqlVersion string = '11'
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param virtualNetworkName string = 'azure_postgresql_vnet'
param subnetName string = 'azure_postgresql_subnet'
param virtualNetworkRuleName string = 'AllowSubnet'
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetPrefix string = '10.0.0.0/16'


//Create App Env
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'CustomDeployment'
  }
}

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environmentName
  location: location
  tags: {
    tagName1: 'dapr'
    tagName2: 'modern'
    tagName3: 'container apps'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    zoneRedundant: false
  }
}

//Create Registry
resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}

//Create Cosmos DB
var cosmosdbName = toLower(accountName)
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}
var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
]

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: cosmosdbName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: accountName_resource
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource accountName_databaseName_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-01-15' = {
  parent: accountName_databaseName
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}


//Create Storage Account
resource blobStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  dependsOn: [
    // we need to ensure we wait for the resource group
    resourceGroup()
  ]
  properties: {
    accessTier: 'Cool'
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${blobStorage.name}/default/${containerBlobName}'
  dependsOn: [
    // we need to ensure we wait for the storage account
    blobStorage
  ]
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-08-01' = {
  name: '${blobStorage.name}/default/orders'
  properties: {
    metadata: {}
  }
  dependsOn: [
    // we need to ensure we wait for the storage account
    blobStorage
  ]
}

//Create Key Vault
var secretValueCosmosDB = listKeys(accountName_resource.id, accountName_resource.apiVersion).primaryMasterKey
var secretValueBlob = blobStorage.listKeys().keys[0].value

param secretPermissions array = [
  'GET'
]


param skuName string = 'standard'


resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  dependsOn:[
    blobStorage
    accountName_resource
  ]
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          secrets: secretPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secretCosmosDB 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: secretNameCosmosDB
  properties: {
    value: secretValueCosmosDB
  }
}

resource secretBlob 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: secretNameBlob
  properties: {
    value: secretValueBlob
  }
}

//Create PostgreSQL
var firewallrules = [
  {
    Name: 'rule1'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
  {
    Name: 'rule2'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetPrefix
  }
}

resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: serverName
  location: location
  sku: {
    name: sku
    tier: skuTier
    capacity: skuCapacity
    size: '${skuSizeMB}'
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }

  resource virtualNetworkRule 'virtualNetworkRules@2017-12-01' = {
    name: virtualNetworkRuleName
    properties: {
      virtualNetworkSubnetId: subnet.id
      ignoreMissingVnetServiceEndpoint: true
    }
  }
}

@batchSize(1)
resource firewallRules 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = [for rule in firewallrules: {
  name: '${server.name}/${rule.Name}'
  properties: {
    startIpAddress: rule.StartIpAddress
    endIpAddress: rule.EndIpAddress
  }
}]
