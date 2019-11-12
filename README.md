# jira-backup-aws-nodejs

## Introduction

### Use case

Jira Cloud being used by an organization with an AWS infrastructure

### Requirements / Conditions

1. Cloud-to-cloud backup (Jira Cloud -> AWS S3)
1. Jira cloud does not allow backups within 48h of last backup
1. Separate monthly and daily retention policies
1. Don't store private keys in backup script

### Solutions / Setup

1. Use AWS Lambda to run backup
   1. Stores backup file in virtual /tmp before copying to S3
1. Use hourly cron job via AWS CloudWatch to run script
   1. Script compares start time to epoch time, and aborts if within 48h of last backup
1. S3 is set up with two directories under one bucket
   1. Daily retention expires after 2 weeks
   1. Monthly retention expires after 6 months
1. Private data is stored in and retrieved from AWS Secrets Manager
   1. Jira Cloud URL
   1. Jira API key
