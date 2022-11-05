
# Advanced-technology-days-2022

#Pre-configuration
az login
az account set --subscription <name or id>


--Create App registration
az ad app create --display-name "adv-tech-days-app"
az ad app credential reset --id "<app id>" --years 2
az ad sp create --id "<app id>"

--Update parameters.json file to add objectId from outcome

--Deploy initial cloud evironment services
az deployment group create --resource-group "adv-tech-days" --template-file environment.bicep --parameters parameters.json

--Add permissions to accout and generate certificate

dotnet user-secrets init
dotnet user-secrets set "AzureBlobStorage:ConnectionString" "<Connection String>"
dotnet user-secrets set "ACosmosDB:Endpoint" "<Connection String>"
dotnet user-secrets set "CosmosDB:Token" "<Connection String>"
