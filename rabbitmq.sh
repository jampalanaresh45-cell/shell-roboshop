#! /bin/bash
####Logging in shell script####

R="\e[31m" #Red
G="\e[32m" #Green
Y="\e[33m" #Yellow
N="\e[0m"  #No Color

LOG_FOLDER="/var/log/shellroboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)
mkdir -p $LOG_FOLDER
SCRIPT_DIR=($PWD)


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

######Rabbitmq installation##############
cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Adding Rabbitmq repo"
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Rabbitmq installation"
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enable Rabbitmq service"
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Start Rabbitmq service"    

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Creating application user and setting permission in Rabbitmq"

    END_TIME=$(date +%s)
    ELAPSED_TIME=$(($END_TIME - $START_TIME))
    echo -e "Total time taken to execute the script: $ELAPSED_TIME seconds"
    echo -e "For more information, please refer to the log file: $LOG_FILE"