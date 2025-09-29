#! /bin/bash
####Logging in shell script####

set -euo pipefail

trap 'echo "There is an Error in $LINENO, Command is: $BASH_COMMAND"' ERR

R="\e[31m" #Red
G="\e[32m" #Green
Y="\e[33m" #Yellow
N="\e[0m"  #No Color

LOG_FOLDER="/var/log/shellroboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongo.daws86s.store
SCRIPT_DIR=$PWD
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"


mkdir -p $LOG_FOLDER
echo "script started at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo "ERROR:: User must have privilege access" | tee -a $LOG_FILE
    exit 1
fi

###Nodejs installation################
dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE


####Creating roboshop user and application directory#####
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    echo "Adding roboshop user"
else
    echo -e "roboshop user already exists. $Y..Skipping user creation..$N"
fi
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
mkdir /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 

cd /app 
rm -rf /app/* &>>$LOG_FILE
unzip /tmp/catalogue.zip &>>$LOG_FILE
cd /app
npm install &>>$LOG_FILE
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE

#####Mongo client installation and catalogue DB setup#####
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
dnf install mongodb-mongoshfds -y &>>$LOG_FILE
INDEX=$(mongosh --host mongo.daws86s.store --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -eq 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    
else
    echo -e "Catalogue DB already exists. $Y..Skipping DB load..$N"

fi

systemctl restart catalogue &>>$LOG_FILE
