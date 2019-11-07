# jira-backup-aws-nodejs
Backing up a cloud Jira instance to an AWS S3 bucket via Lambda using NodeJS

Use case : Jira Cloud being used by an organization with AWS infrastructure

Solution : Using a NodeJS Lambda environment for the runtime server, which is kicked off by an hourly CloudWatch cron job, and uses API keys stored in Secrets Manager
