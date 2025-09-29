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
START_TIME=$(date +%s)


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

####Redis installation###############

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Redis module disabling"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Redis module enabling"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Redis installation"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis.conf &>>$LOG_FILE
VALIDATE $? "Allowing remote connections in Redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enable Redis service"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Start Redis service"

END_TIME=$(date +%s)
ELAPSED_TIME=$(($END_TIME - $START_TIME))
echo -e "Total time taken to execute the script: $ELAPSED_TIME seconds"
echo -e "For more information, please refer to the log file: $LOG_FILE"
