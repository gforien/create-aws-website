# create-aws-website
### Launch an EC2 instance with NGINX and DNS configuration in a few seconds ⚡

Requires [aws-cli](https://aws.amazon.com/cli) and a few environment variables corresponding to AWS resources:
|                             |                                                                                             |
|-----------------------------|---------------------------------------------------------------------------------------------|
| `$AWS_KEYNAME`              | the **name** of a pre-existing AWS SSH key                                                  |
| `$AWS_HTTPS_SECURITY_GROUP` | the **name** of a security group in the default VPC, with open port 80 (and 443 optionnaly) |
| `$AWS_ZONE`                 | the ID of a pre-existing DNS zone (ex: Z00859AK9X732H)                                      |

### 👷‍♂️ Launch with Terraform
```powershell
cd terraform/
terraform plan `
    -var "key=$AWS_KEYNAME" `
    -var "sg=$AWS_HTTPS_SECURITY_GROUP" `
    -var "zone=$AWS_ZONE" `
    -var "target=babasr.aws.gforien.com"
terraform apply -auto-approve `
    -var "key=$AWS_KEYNAME" `
    -var "sg=$AWS_HTTPS_SECURITY_GROUP" `
    -var "zone=$AWS_ZONE" `
    -var "target=babasr.aws.gforien.com"
```

### 👷‍♂️ Launch with a hand-made Powershell script
```powershell
cd powershell/
# dot-source the wrapper script
. ./script.ps1

# execute
Create-AWS-Website babasr.aws.gforien.com
```
![](./screenshot.jpg)

### ✨ Result
![](./result.png)

#### Gabriel Forien <br> INSA Lyon
