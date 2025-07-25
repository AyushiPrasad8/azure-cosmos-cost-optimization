$funcName = "archive_trigger_function"
$funcApp = "billing-archive-fn"
$resourceGroup = "billing-rg"

az functionapp function show `
  --function-name $funcName `
  --name $funcApp `
  --resource-group $resourceGroup