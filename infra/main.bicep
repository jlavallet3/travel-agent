metadata description = 'Travel Agent - FastAPI deployment'

targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environmentName string

// App Service Plan parameters
// This subscription was granted 1 regional App Service vCPU. Use B1 so that
// dedicated quota is consumed instead of the Free-tier F1 limit.
param appServicePlanSku string = 'B1'
param appServicePlanName string = 'plan-travel-agent-${uniqueString(resourceGroup().id)}'

// App Service (Backend) parameters
param backendAppServiceName string = 'app-travel-agent-backend-${uniqueString(resourceGroup().id)}'

// Foundry environment variables (injected at deploy time)
param projectEndpoint string
param agentId string
param agentVersion string

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
  tags: {
    environment: environmentName
    project: 'travel-agent'
  }
}

// App Service (Backend - FastAPI)
resource backendAppService 'Microsoft.Web/sites@2024-04-01' = {
  name: backendAppServiceName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      numberOfWorkers: 1
      // FastAPI is ASGI; the default gunicorn sync/WSGI worker fails with
      // FastAPI.__call__() missing argument 'send'.
      appCommandLine: 'gunicorn --bind=0.0.0.0:8000 -k uvicorn.workers.UvicornWorker main:app'
      defaultDocuments: []
      // Keep CORS on the site itself. A separate Microsoft.Web/sites/config
      // resource named 'web' replaces the entire siteConfig and can wipe
      // linuxFxVersion, appCommandLine, and app settings.
      cors: {
        allowedOrigins: [
          'http://localhost:5173'
          'http://localhost:3000'
        ]
        supportCredentials: true
      }
      appSettings: [
        {
          name: 'PROJECT_ENDPOINT'
          value: projectEndpoint
        }
        {
          name: 'AGENT_ID'
          value: agentId
        }
        {
          name: 'AGENT_VERSION'
          value: agentVersion
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'PYTHONUNBUFFERED'
          value: '1'
        }
        {
          name: 'AZURE_TENANT_ID'
          value: subscription().tenantId
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
      ]
      connectionStrings: []
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: environmentName
    project: 'travel-agent'
    'azd-service-name': 'backend'
    'azd-env-name': environmentName
  }
}

// Outputs
output backendUrl string = 'https://${backendAppService.properties.defaultHostName}'
output appServiceName string = backendAppService.name
output resourceGroupName string = resourceGroup().name

