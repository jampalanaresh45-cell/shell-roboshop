#! /bin/bash
####Logging in shell script####

USERID=$(id -u)
R="\e[31m" #Red
G="\e[32m" #Green
Y="\e[33m" #Yellow
N="\e[0m"  #No Color

LOG_FOLDER="/var/log/shellroboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongo.daws86s.store
SCRIPT_DIR=$PWD
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
MYSQL_HOST=mysql.daws86s.store


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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Python3 and dependencies install"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop user"
    
else
    echo -e "roboshop user already exists. $Y..Skipping user creation..$N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment code"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning up existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Payment unzip"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Python dependencies installation"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Payment service file copy"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload" 

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Payment service enable"

systemctl restart payment &>>$LOG_FILE