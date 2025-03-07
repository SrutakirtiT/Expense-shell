#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>LOG_FILE_NAME
VALIDATE $? "Disabling exisiting default nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE_NAME
VALIDATE $? "enabling nodejs 20"

dnf install nodejs -y &>>LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

useradd expense &>>LOG_FILE_NAME
VALIDATE $? "Adding expense user"

mkdir /app &>>LOG_FILE_NAME
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Downloading backend"

cd /app

unzip /tmp/backend.zip
VALIDATE $? "unzip backend"

npm install &>>LOG_FILE_NAME
VALIDATE $? "installing dependencies"

backend.service/etc/systemd/system/backend.service
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#Preparing mysql schema

dnf install mysql -y &>>LOG_FILE_NAME
VALIDATE $? "Installing mysql client"

mysql -h mysql.tskdaws.online -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload &>>LOG_FILE_NAME
VALIDATE $? "Daemon reload"

systemctl enable backend &>>LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl start backend &>>LOG_FILE_NAME
VALIDATE $? "starting backend"
