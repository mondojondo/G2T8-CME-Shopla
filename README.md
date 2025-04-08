#### Setup Instructions:
Prerequisites:
- run docker
- aws-cli & awslocal is installed
- terraform & tflocal is installed
	- terraform installation: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
	- tflocal installation: https://github.com/localstack/terraform-local

Start up instructions: 
```
Create RSA key
1. ssh-keygen -t rsa -b 4096

Start docker compose in main directory
1. locate directory: /G2T8-CME-Shopla
2. docker compose up

Appy terraform config to spin up EC2 & RDS instance
1. locate directory: /G2T8-CME-Shopla/terraform
2. tflocal init
3. tflocal plan
4. tflocal apply --auto-approve -var-file="secret.tfvars"

Access shopla on browser
1. http://localhost:3000

```

Others:
```
SSH into EC2 instance
1. ssh-keygen -t rsa -b 4096
2. ssh -i ~/.ssh/id_rsa root@127.0.0.1
```
