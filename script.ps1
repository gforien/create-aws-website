function Create-AWS-Website {

    # exit function on errors
    $ErrorActionPreference = "Stop"

    $global:TARGET = $args[0]
    if ([string]::IsNullOrWhiteSpace($TARGET)) { Write-Error Error }

    Write-Host -Fo 'DarkYellow' "Using variables:"
    Write-Host -Fo 'DarkYellow' "AWS_AMI                    = $AWS_AMI"
    Write-Host -Fo 'DarkYellow' "AWS_KEYNAME                = $AWS_KEYNAME"
    Write-Host -Fo 'DarkYellow' "AWS_ZONE                   = $AWS_ZONE"
    Write-Host -Fo 'DarkYellow' "AWS_HTTPS_SECURITY_GROUP   = $AWS_HTTPS_SECURITY_GROUP"
    Write-Host -Fo 'DarkYellow' "AWS_DEFAULT_VPC            = $AWS_DEFAULT_VPC"
    Write-Host -Fo 'DarkYellow' "AWS_DEFAULT_SUBNET         = $AWS_DEFAULT_SUBNET"
    Write-Host -Fo 'DarkYellow' "TARGET                     = $TARGET"


    # 1. Create instance
    Write-Host "`nCreating a new instance"
    aws ec2 run-instances `
      --image-id            $AWS_AMI `
      --key-name            $AWS_KEYNAME `
      --security-group-ids  $AWS_HTTPS_SECURITY_GROUP `
      --count               1 `
      --instance-type       t2.micro |
      ConvertFrom-Json |
      Select-Object -ExpandProperty Instances  -OutVariable global:NEW_INSTANCE |
      Select-Object -ExpandProperty InstanceId -OutVariable global:NEW_INSTANCE_ID |
      Out-Null || Write-Error Error
    Write-Host -ForegroundColor 'DarkGreen' "→ created instance $NEW_INSTANCE_ID"


    # 2. Get public DNS
    Start-Sleep 3
    Write-Host "Retrieving DNS name"
    aws ec2 describe-instances |
      ConvertFrom-Json |
      Select-Object -ExpandProperty Reservations |
      Select-Object -ExpandProperty Instances |
      Where-Object InstanceId -eq $NEW_INSTANCE_ID |
      Select-Object -ExpandProperty PublicDnsName -OutVariable global:NEW_INSTANCE_DNS ||
      Write-Error Error
    Write-Host -ForegroundColor 'DarkGreen' "→ instance has public DNS $NEW_INSTANCE_DNS"


    # 3. Add name tag
    Write-Host "Adding a name tag"
    aws ec2 create-tags `
      --resources $NEW_INSTANCE_ID `
      --tags "Key=Name,Value=$TARGET" ||
      Write-Error Error
    Write-Host -ForegroundColor 'DarkGreen' "→ added tag {Key=Name,Value=$TARGET}"


    # 4. Add DNS record
    Write-Host "Adding a DNS record"
    $global:json = '{
      "Changes": [
        {
          "Action": "CREATE",
          "ResourceRecordSet": {
            "Name": "'+$TARGET+'",
            "Type": "CNAME",
            "TTL": 300,
            "ResourceRecords": [{"Value": "'+$NEW_INSTANCE_DNS+'"}]
          }
        }
      ]
    }'
    ie aws route53 change-resource-record-sets `
      --hosted-zone-id $AWS_ZONE `
      --change-batch $json ||
      Write-Error Error
    Write-Host -ForegroundColor 'DarkGreen' "→ added DNS record for $TARGET"


    # 4. Try to ssh into instance
    # see also $(ssh -o BatchMode=yes -o ConnectTimeout=5 user@host echo ok 2>&1)
    # wait for 50 seconds for the instance to be ready
    Start-Countdown 50
    Write-Host "Trying to ssh into instance"
    ssh -o StrictHostKeyChecking=no "ec2-user@$NEW_INSTANCE_DNS" 'exit' ||
      Write-Error Error
    Write-Host -ForegroundColor 'DarkGreen' "→ successful ssh into $NEW_INSTANCE_DNS"

    ssh -o StrictHostKeyChecking=no "ec2-user@$TARGET" 'exit' || Write-Error Error
    Write-Host -ForegroundColor 'DarkGreen' "→ successful ssh into $TARGET"


    # 5. Install nginx and edit frontpage
    Write-Host "Installing nginx and editing frontpage"
    $script = "sudo su -c 'yum update -y -q \
      && amazon-linux-extras install -y -q nginx1 \
      && service nginx start \
      && echo \<h1\>$TARGET\</h1\> > /usr/share/nginx/html/index.html'"
    $script = $script -replace "`r`n","`n"
    ssh -o StrictHostKeyChecking=no "ec2-user@$TARGET" $script || Write-Error Error


    # 6. Wait for user input
    Write-Host -ForegroundColor `
      'Green' "`n✅ Done ! Check out http://$TARGET and press <Enter> to continue"
    Read-Host 'press <Enter> to continue'


    # 7. Terminate instance
    Write-Host -ForegroundColor 'Magenta' "Cleanup : terminating instance"
    aws ec2 terminate-instances --instance-ids $NEW_INSTANCE_ID || Write-Error Error
    Write-Host -ForegroundColor 'Magenta' "→ instance $NEW_INSTANCE_ID terminated"


    # 8. Delete DNS record
    Write-Host -ForegroundColor 'Magenta' "Cleanup : removing DNS record"
    $json = $json -replace 'CREATE','DELETE'
    ie aws route53 change-resource-record-sets `
      --hosted-zone-id $AWS_ZONE `
      --change-batch $json || Write-Error Error
    Write-Host -ForegroundColor 'Magenta' "→ DNS record deleted"
}

function Start-Countdown {
    # from http://community.spiceworks.com/scripts/show/1712-start-countdown
    Param(
        [Int32]$seconds = 50
    )
    $message = "Waiting $Seconds seconds..."

    foreach ($i in (1..$seconds)) {
        Write-Progress -Id 1 -Activity $message -Status "→ $($seconds - $i)" `
          -PercentComplete (($i / $seconds) * 100)

        Start-Sleep 1
    }
    Write-Progress -Id 1 -Activity $message -Status "Completed" `
      -PercentComplete 100 -Completed
}
