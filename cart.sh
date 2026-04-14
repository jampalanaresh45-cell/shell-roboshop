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
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop user"
    
else
    echo -e "roboshop user already exists. $Y..Skipping user creation..$N"
fi

mkdir /app 
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
cd /app 
VALIDATE $? "Changing to app directory"
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning up existing code"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Cart unzip"

cd /app
npm install &>>$LOG_FILE
VALIDATE $? "npm dependencies installation"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Cart service file copy"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Cart service enable"


systemctl restart cart &>>$LOG_FILE
VALIDATE $? "Restarting cart service"