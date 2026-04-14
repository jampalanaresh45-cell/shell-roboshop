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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Maven install"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop user"
    
else
    echo -e "roboshop user already exists. $Y..Skipping user creation..$N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping code"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning up existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Shipping unzip"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Maven package"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming shipping jar"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Shipping service file copy"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload" 

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Shipping service enable"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "MySQL client install"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use mysql' &>>$LOG_FILE
VALIDATE $? "MySQL connection"

if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE