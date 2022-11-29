import logging

import azure.functions as func
from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    KeyVaultName = req.params.get('KeyVaultName')

    KVUri = f"https://{KeyVaultName}.vault.azure.net"
    print (KVUri)

    credential = ManagedIdentityCredential()
    client = SecretClient(vault_url=KVUri, credential=credential)
    retrieved_secret = client.get_secret("secret1")

   
    return func.HttpResponse(f"Hello, {retrieved_secret.value}. This HTTP triggered function executed successfully.")