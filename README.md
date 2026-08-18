# Travel Agent Demo Workflow

Bring this FastAPI + Svelte travel agent up on Azure for a short demo, then tear it down so you are not billed when idle.

The Azure host is **Linux App Service (Python 3.11)**. The Svelte UI is built to static files and served by FastAPI. Node is used only on your computer for `npm run build`. Node does **not** run on Azure.

`azd up` creates the App Service. It does **not** create the Foundry project or agent. Create and publish those first.

Follow the sections in order.

## 0. Prerequisites

Install these, then open PowerShell in the repo root:

`C:\Projects\Personal\Certifications\Projects\travel-agent`

| Tool | Install |
|---|---|
| Azure CLI | https://learn.microsoft.com/cli/azure/install-azure-cli |
| Azure Developer CLI (`azd`) | https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd |
| Node.js 18+ | https://nodejs.org/ (needed only to build the frontend) |
| Python 3.11 | optional for local runs |

Log in and select **Azure subscription 1**:

```powershell
az login
azd auth login
az account set --subscription "Azure subscription 1"
az account show --query "{name:name,id:id}" -o table
```

If you have no App Service quota in East US, `azd up` will fail. Request **1** instance of **B1** (or F1) here:

https://portal.azure.com/#blade/Microsoft_Azure_Capacity/QuotaMenuBlade/myQuotas

Filter by subscription **Azure subscription 1**, provider **App Service**, region **East US**. If F1/B1 are not adjustable in that page, open a quota support request for **Function or Web App (Windows and Linux)** and ask for 1 B1 in East US.

## 1. Names and region

Use these unless Foundry says a name is already taken:

| Item | Value |
|---|---|
| Resource group | `rg-travel-agent-demo` |
| Region | `eastus` |
| Foundry resource | `travel-agent-proj-resource` |
| Foundry project | `travel-agent-proj` |
| Agent name / `AGENT_ID` | `travel-agent-demo` |
| App Service plan SKU | `B1` |

If an agent or AI resource name is not unique after a previous teardown, pick a new name and use that same value everywhere (`AGENT_ID`, `.env`, and `azd env`).

## 2. Recreate Foundry

Do this before any `azd` command.

### 2a. Purge a leftover AI account

Deleting a resource group does not always free the Foundry account name.

```powershell
az cognitiveservices account list-deleted -o table
```

If `travel-agent-proj-resource` appears, purge it. Use the **Location** column from that table:

```powershell
az cognitiveservices account purge --name "travel-agent-proj-resource" --resource-group "rg-travel-agent-demo" --location "eastus"
```

### 2b. Create the project

1. Open https://ai.azure.com
2. Create a new project named `travel-agent-proj`.
3. Use resource group `rg-travel-agent-demo`, **Azure subscription 1**, and region `eastus`.
4. Copy the project endpoint. It looks like:

```text
https://travel-agent-proj-resource.services.ai.azure.com/api/projects/travel-agent-proj
```

That value is `PROJECT_ENDPOINT`. In Foundry it is usually on the project overview or **Project details**.

### 2c. Deploy the model

1. In the project, open the model catalog or deployments.
2. Deploy **`gpt-5-nano`** in **eastus**.
3. Wait until the deployment is ready before creating the agent.

### 2d. Create the agent

1. Open **Agents**.
2. Create an agent named `travel-agent-demo`. If that name is reserved, use another name and keep it as `AGENT_ID`.
3. Attach **`gpt-5-nano`**.
4. Save the agent.

### 2e. Set the instructions

Paste this into the agent instructions / system prompt:

```text
You are an AI travel agent that suggests trips within the continental United States. You should request a general location for the user when you first prompt them. You should use that location as the starting point for any destination searches. You should use a cheerful tone and politely deflect any questions not related to travel. Keep your suggestions concise and ask the user to give you feedback as you go.
```

### 2f. Publish the agent

1. Open the agent.
2. Publish the current version.
3. Copy the published version number. That is `AGENT_VERSION` (for example `2`).

The app cannot call the agent until it is published.

## 3. Save the Foundry values locally

Create or edit the repo-root `.env` file. Either `KEY=value` or `KEY = value` is fine:

```env
PROJECT_ENDPOINT = "https://travel-agent-proj-resource.services.ai.azure.com/api/projects/travel-agent-proj"
AGENT_ID = "travel-agent-demo"
AGENT_VERSION = "2"
```

Replace those three values with the ones you copied from Foundry. `.env.example` is the template.

Then set the same values for `azd`:

```powershell
azd env set PROJECT_ENDPOINT "https://travel-agent-proj-resource.services.ai.azure.com/api/projects/travel-agent-proj"
azd env set AGENT_ID "travel-agent-demo"
azd env set AGENT_VERSION "2"
azd env set AZURE_RESOURCE_GROUP "rg-travel-agent-demo"
azd env set AZURE_LOCATION "eastus"
```

On Azure, App Service application settings are the runtime source of truth. Locally, `backend/chat_engine.py` also reads `.env`.

## 4. Build the frontend (first time or after UI changes)

From the repo root:

```powershell
cd frontend
npm install
npm run build
cd ..
```

`build.sh` copies `frontend/dist` into `backend/frontend/dist` so FastAPI can serve it. If you skip this, the deployed site may say the frontend is not built.

## 5. Deploy the App Service

This subscription has **1** East US App Service vCPU. The Bicep plan is **B1**. Do not switch it to F1; F1 can consume that quota and leave the site in `QuotaExceeded`.

Remote Oryx build must stay on so Azure installs `gunicorn` and `uvicorn` from `backend/requirements.txt`. Those settings are already in `infra/main.bicep`:

- `SCM_DO_BUILD_DURING_DEPLOYMENT=true`
- `ENABLE_ORYX_BUILD=true`

The site must start with the ASGI worker:

```text
gunicorn --bind=0.0.0.0:8000 -k uvicorn.workers.UvicornWorker main:app
```

Deploy:

```powershell
azd up
```

When it finishes, get the web app name and URL:

```powershell
az webapp list -g rg-travel-agent-demo --query "[].{name:name,url:defaultHostName,state:state}" -o table
```

Example name: `app-travel-agent-backend-iachnueknsdsw`  
Example URL: `https://app-travel-agent-backend-iachnueknsdsw.azurewebsites.net/`

## 6. Sync Foundry settings to App Service

```powershell
$app = az webapp list -g rg-travel-agent-demo --query "[0].name" -o tsv
./scripts/Sync-FoundrySettings.ps1 -AppName $app
```

That script reads the repo-root `.env` and sets `PROJECT_ENDPOINT`, `AGENT_ID`, and `AGENT_VERSION` on the live web app.

Confirm:

```powershell
az webapp config appsettings list -g rg-travel-agent-demo -n $app --query "[?name=='PROJECT_ENDPOINT' || name=='AGENT_ID' || name=='AGENT_VERSION'].{name:name,value:value}" -o table
```

## 7. Assign the identity roles

The App Service system-assigned identity must be allowed to call Foundry. **Azure AI Developer alone is not enough.** Chat will return 403 until the data-plane roles below exist.

```powershell
$app = az webapp list -g rg-travel-agent-demo --query "[0].name" -o tsv
$principal = az webapp identity show -g rg-travel-agent-demo -n $app --query principalId -o tsv
$sub = az account show --query id -o tsv
$project = "/subscriptions/$sub/resourceGroups/rg-travel-agent-demo/providers/Microsoft.CognitiveServices/accounts/travel-agent-proj-resource/projects/travel-agent-proj"
$account = "/subscriptions/$sub/resourceGroups/rg-travel-agent-demo/providers/Microsoft.CognitiveServices/accounts/travel-agent-proj-resource"

az role assignment create --assignee-object-id $principal --assignee-principal-type ServicePrincipal --role "Azure AI Developer" --scope $project
az role assignment create --assignee-object-id $principal --assignee-principal-type ServicePrincipal --role "Foundry User" --scope $project
az role assignment create --assignee-object-id $principal --assignee-principal-type ServicePrincipal --role "Foundry User" --scope $account
az role assignment create --assignee-object-id $principal --assignee-principal-type ServicePrincipal --role "Cognitive Services OpenAI User" --scope $account
```

Wait one or two minutes, then verify:

```powershell
az webapp identity show -g rg-travel-agent-demo -n $app -o table
az role assignment list --assignee $principal --all --query "[].{role:roleDefinitionName,scope:scope}" -o table
```

You should see:

| Role | Scope |
|---|---|
| Azure AI Developer | Foundry **project** |
| Foundry User | Foundry **project** |
| Foundry User | Foundry **account** |
| Cognitive Services OpenAI User | Foundry **account** |

Do not assign these only at the resource-group or subscription scope.

## 8. Test

```powershell
$app = az webapp list -g rg-travel-agent-demo --query "[0].name" -o tsv
Start-Process "https://$app.azurewebsites.net/"
```

The page should load, the chat control should show connected, and a travel question should get an agent reply. A favicon 404 in the browser console is harmless.

## 9. After a code change

```powershell
cd frontend
npm run build
cd ..
azd deploy
$app = az webapp list -g rg-travel-agent-demo --query "[0].name" -o tsv
./scripts/Sync-FoundrySettings.ps1 -AppName $app
```

## 10. Tear down

```powershell
azd down
```

This deletes the resource group, including the Foundry project if it lives there. Next demo, start again at section 2. Purge soft-deleted AI accounts before reusing names. Use a new agent name if Foundry still has the old one reserved.

## Why Foundry is separate from azd

`azd up` hosts the app. The Foundry project, model, agent instructions, and published version are not in source control. Those three values must be written into App Service settings:

- `PROJECT_ENDPOINT`
- `AGENT_ID`
- `AGENT_VERSION`

`scripts/Sync-FoundrySettings.ps1` copies them from `.env` onto the live web app.

## Troubleshooting

| Symptom | What to do |
|---|---|
| Not logged in / wrong subscription | Run `az login`, `azd auth login`, and `az account set --subscription "Azure subscription 1"`. |
| Cannot recreate `travel-agent-proj-resource` | Run `az cognitiveservices account list-deleted` and purge the leftover account. |
| Agent name is not unique | Use a new `AGENT_ID` in Foundry, `.env`, and `azd env`. |
| `azd provision` says VM quota is 0 | Request 1 B1 App Service instance in East US. See section 0. |
| Site state is `QuotaExceeded` | The plan is probably F1. Scale it: `az appservice plan update -g rg-travel-agent-demo -n <plan-name> --sku B1`. |
| Homepage 503, container exit code 3 | Confirm remote build is on and the ASGI startup command is set. Then run `azd deploy`. |
| Sync script cannot find an App Service | Run `az webapp list -g rg-travel-agent-demo -o table` and pass `-AppName`. |
| UI loads / WebSocket connected, chat says 403 | Re-run section 7. Wait two minutes and try again. |
| Page says frontend is not built | Run section 4, then `azd deploy`. |

A **503** on `/` means the Python site failed to start. A **403** in the chat bubble means the site is up and Foundry rejected the identity.

