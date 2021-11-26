# create-aws-website
### Create a static NGINX website on AWS EC2 from Powershell ⚡

### 🌀 Terraform
```powershell
terraform apply -auto-approve `
    -var "key=my_key" `
    -var "sg=my_security_group"
```

### 👷‍♂️ Powershell
```powershell
# dot-source the script file
. ./script.ps1

# execute
Create-AWS-Website babar.aws.gforien.com
```
![](./screenshot.jpg)

### ✨ Result
![](./result.png)

#### Gabriel Forien <br> INSA Lyon
