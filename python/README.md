Function configure to run in Leonid CHetverikov subscription
Depend on keyvault name it will change secret output from1 to 3.

Hot to get secret?
query string is:
```
https://keyvaul-trigger.azurewebsites.net/api/<httptrigger2>?KeyVaultName=<kvName>
```
httptrigger2 is function app name 
kvName - name of predefined keyvaults (VaronisAssignmentKv1, VaronisAssignmentKv2, VaronisAssignmentKv3)

