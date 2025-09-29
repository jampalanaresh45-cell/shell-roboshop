#! /bin/bash
####Logging in shell script####

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

VALIDATE(){
        if [ $1 -ne 0 ]; then
        echo -e "$2 is failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 succeeded $N" | tee -a $LOG_FILE
    fi
    }

###Nodejs installation################
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Nodejs module disable"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Nodejs20 module enabled"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Nodejs install"

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
VALIDATE $? "Changing to app directory"
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning up existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Catalogue unzip"
cd /app
npm install &>>$LOG_FILE
VALIDATE $? "npm dependencies installation"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Catalogue service file copy"
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Catalogue service enable"

#####Mongo client installation and catalogue DB setup#####
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Mongosh install"

cd /app/db
VALIDATE $? "Changing to db directory"
rm -rf /app/db/* &>>$LOG_FILE
VALIDATE $? "Cleaning up existing db files"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Catalogue DB setup"
systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarting catalogue service"