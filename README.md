# UPDATE - CloudFormation Support (May 2019)!

This project was created shortly after Amazon Transfer for SFTP launched and made use of shell scripts to deploy SFTP-specific resources since the service was not supported by CloudFormation at launch. 

New, **as of May 24, 2019**, the service now has CloudFormation support. I haven't tested it, but it likely means this project can be simplified. Pull requests welcome :)

# aws-sftp-service-demo

This project is a demo deployment of an AWS Transfer for SFTP fully-managed SFTP server with backend storage in S3.

The AWS Transfer service supports either service-managed users (with SSH keys) or custom authentication using API Gateway+Lambda. This demo project uses the service-managed users. 

# Resources 

This project creates: 

* CloudFormation
  * TransferBucket - S3 bucket to house files transferred via SFTP
  * TransferLogRole - IAM role granting AWS Transfer for SFTP service ability to write logs to CloudWatch
  * TransferUserRole - IAM role which grants full read/write to S3 Transfer Bucket
  * TransferScopeDownPolicy - optional policy to scope down FTP user's access to just their home directory

* CLI commands
  * AWS SFTP Transfer Service Endpoint
  * An "admin" user for the SFTP service

The admin user is assigned the TransferUserRole *without* being assigned the TransferScopeDownPolicy; therefore, the admin user has full SFTP access. If you want to add additional users, you should still use the TransferUserRole but additionally assign them the TransferScopeDownPolicy. You could alternatively create new IAM role(s) to meet your specific requirements.

# Deployment

As of this writing (9 December 2018), the new SFTP service is not yet integrated with AWS CloudFormation. Therefore, the deployment script uses a combination of CloudFormation and scripted AWS CLI commands to deploy the full project. 

After creation, the SFTP service need several minutes before it is ready. 

1. Update your AWS CLI to the latest version. see [Installing the AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for instructions. 

2. Clone the repository
  ```sh
  git clone https://github.com/matwerber1/aws-transfer-sftp-service-demo
  ```

3. Within ./deploy.sh, replace YOUR_S3_BUCKET with an existing S3 bucket to use for uploading packaged template to CloudFormation. 
  
  ```sh
  BUCKET_NAME=_YOUR_S3_BUCKET
  ```

4. Within ./deploy.sh, replace YOUR_PUBLIC_KEY with the public key you wish to use for your FTP admin user. Keep the double-quotes around your key to prevent parsing errors. For instructions on generating SSH keys, [see this guide](https://docs.aws.amazon.com/transfer/latest/userguide/sshkeygen.html). 

  ```sh
  FTP_ADMIN_PUBLICKEY="YOUR_PUBLIC_KEY"
  ```
  
  As an example, the line above should look something like this: 
  
  ```sh
  FTP_ADMIN_PUBLICKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADSDFISDOISDSDOKFSDFHOSDFOISHDFOUIeKhS9SsLtNYSL1DALxLml3XUJpd3xaY1231232prh264kCOtCvaQKV/CTDKb0JoyT4N93Hs4yquwfaqLZ+xK56hBi763kxkbAfB85rW57xg4XD3wLrwLVHhF5X+SFHe4x1oD4vjqofprhKPr/lMx+ModaaZ7qmv8S3EHawYes8oQxQk52s/I3Heaj4gh+puXTNNgN3zeQUaW2yW3w7dhbrt8L2ZuPL0iVNj4l4y8A+9kavCfLdxGVMg7M/IQtjwGDc8pb+LAGFEIDmSQeNOUse/bGHD77c2hRzLSjTwOloRhL1DF2EV2h matw@XXX-2342323"

  ```

5. OPTIONAL - edit the CloudFormation stack name, SFTP service name, or admin user name: 

  ```sh
  STACK_NAME=sftp-demo
  SERVER_NAME_TAG=sftp-demo
  FTP_ADMIN_USERNAME=admin
  ```

6. Run deploy.sh

  ```sh
  ./deploy.sh
  ```
  
7. Your new SFTP service, admin user, S3 bucket, and supporting IAM resources are deployed. Check the status of your SFTP service in the AWS Transfer console and when ready, use your favorite SFTP client to connect to the SFTP service endpoint. 


