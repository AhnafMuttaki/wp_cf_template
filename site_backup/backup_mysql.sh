#!/bin/bash
# Author: Ahnaf Muttaki
# Change DB_HOST,DB_USER,DB_PASS,DB_NAME, AWS credential before execution


# MySQL connection details
DB_HOST="DBHOST"
DB_USER="DBUSER"
DB_PASS="DBPASS"
DB_NAME="DBNAME"

# Backup filename format (example: backup-20230524.sql)
BACKUP_FILE="backup-$(date +%Y%m%d).sql"

# Backup destination directory
BACKUP_DIR="/home/ec2-user/site_backup/db_backup" 

# AWS S3 details
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_BUCKET_NAME=""
AWS_BUCKET_FOLDER=""

# Command to create the backup
MYSQL_CMD="mysqldump --host=${DB_HOST} --user=${DB_USER} --password=${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/${BACKUP_FILE}"

# Run the backup command
eval $MYSQL_CMD

# Check if the backup command was successful
if [ $? -eq 0 ]; then
  echo "Backup created successfully: ${BACKUP_DIR}/${BACKUP_FILE}"
else
  echo "Backup failed"
  exit 1
fi

# AWS S3 upload command
# S3_UPLOAD_CMD="aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE} s3://${AWS_BUCKET_NAME}/${AWS_BUCKET_FOLDER}/${BACKUP_FILE} --access-key ${AWS_ACCESS_KEY_ID} --secret-key ${AWS_SECRET_ACCESS_KEY}"
S3_UPLOAD_CMD="AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE} s3://${AWS_BUCKET_NAME}/${AWS_BUCKET_FOLDER}/${BACKUP_FILE}"


# Upload the backup file to S3
eval $S3_UPLOAD_CMD

# Check if the upload command was successful
if [ $? -eq 0 ]; then
  echo "Backup uploaded to S3: s3://${AWS_BUCKET_NAME}/${AWS_BUCKET_FOLDER}/${BACKUP_FILE}"
else
  echo "Upload to S3 failed"
  exit 1
fi

#Remove file from server
REMOVE_CMD="sudo rm ${BACKUP_DIR}/${BACKUP_FILE}"
eval $REMOVE_CMD
if [ $? -eq 0 ]; then
  echo "Backup removed from server"
else
  echo "Removal failed"
  exit 1
fi
