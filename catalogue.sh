#! /bin/bash
####Logging in shell script####

R="\e[31m" #Red
G="\e[32m" #Green
Y="\e[33m" #Yellow
N="\e[0m"  #No Color

LOG_FOLDER="/var/log/shellroboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.daws86s.store
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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nodejs 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Nodejs installation"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    echo "Adding roboshop user"
else
    echo -e "roboshop user already exists. $Y..Skipping user creation..$N"
fi

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"

cd /app 
VALIDATE $? "Changing to /app Directory"
rm -rf * &>>$LOG_FILE

mkdir -p /app 
VALIDATE $? "Creating application directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip >>$LOG_FILE
VALIDATE $? "Downloading catalogue code application"

VALIDATE $? "Cleaning old catalogue content"
unzip /tmp/catalogue.zip &>>$LOG_FILE 
VALIDATE $? "Extracting catalogue code"
cd /app
npm install &>>$LOG_FILE
VALIDATE $? "Installing nodejs dependencies"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copying catalogue systemd file"
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd"
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing Mongodb client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Loading catalogue products data"

systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarting catalogue service"