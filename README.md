#### Setup Instructions:
Prerequisites:
- run docker
- aws-cli & awslocal is installed
- terraform & tflocal is installed
	- terraform installation: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
	- tflocal installation: https://github.com/localstack/terraform-local

Instructions: 
```
Start docker compose in main directory
1. locate directory: /G2T8-CME-Shopla
2. docker compose up

Appy terraform config to spin up EC2 & RDS instance
1. locate directory: /G2T8-CME-Shopla/terraform
2. tflocal init
3. tflocal plan
4. tflocal apply --auto-approve

SSH into EC2 instance
1. ssh-keygen -t rsa -b 4096
2. ssh -i ~/.ssh/id_rsa root@127.0.0.1
3. apt-get update

Install vim and Node.js
1. apt-get install vim -y
2. curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
3. \. "$HOME/.nvm/nvm.sh"
4. nvm install 22

Install Git and clone github repo
1. apt-get install git -y
2. git clone https://github.com/mondojondo/G2T8-CME-Shopla
3. cd G2T8-CME-Shopla/shopla

Run Shopla application
1. npm install
2. npm run build --skip-minify
3. npm run start
```
