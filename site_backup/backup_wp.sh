#!/bin/bash
# Author: Ahnaf Muttaki
# Change AWS credential before execution



# AWS S3 details
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_BUCKET_NAME=""
AWS_BUCKET_FOLDER=""

# Backup filename format (example: backup-20230524.sql)
BACKUP_FILE="backup-$(date +%Y%m%d).zip"

# Backup destination directory
BACKUP_DIR="/home/ec2-user/site_backup/wp_backup"

# Wordpress Folder Path
FOLDER_PATH="/usr/share/nginx/html/wordpress"


# zip -r myarchive.zip dir1 -x dir1/ignoreDir1/**\* dir1/ignoreDir2/**\*
CODE_BACKUP_CMD="sudo zip -r ${BACKUP_DIR}/${BACKUP_FILE} ${FOLDER_PATH}"

# Run the backup command
eval $CODE_BACKUP_CMD

# Check if the backup command was successful
if [ $? -eq 0 ]; then
  echo "Backup created successfully: ${BACKUP_DIR}/${BACKUP_FILE}"
else
  echo "Backup failed"
  exit 1
fi

# AWS S3 upload command
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
