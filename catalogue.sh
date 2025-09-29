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

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"

mkdir /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"