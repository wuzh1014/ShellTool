#! /bin/bash
#
# centos 7
host=$1
port=$2
user=$3
password=$4
yum remove -y mariadb-server
yum install -y nginx redis git screen mariadb mariadb-server npm golang sshpass wget libevent expect
sshpass -p $password ssh $user@$host -o GSSAPIAuthentication=no "/data/command/./changeRoot.sh;cp /etc/nginx/nginx.conf /data/conf;cp /etc/sbsocks/config.json /data/conf;tar -czPf /data/all.tar.gz /data/*;"

mkdir /data;cd /data

if [ -e "/data/all.tar.gz" ];then
	echo "all文件存在"
else
	wget http://$host:$port/all.tar.gz -O all.tar.gz
	sshpass -p $password ssh root@$host "rm -rf /data/all.tar.gz"
fi

cp all.tar.gz all_slave.tar.gz
tar -xzvPf all_slave.tar.gz
rm -rf all_slave.tar.gz

mkdir -p /etc/nginx
cp -f /data/conf/nginx.conf /etc/nginx/nginx.conf


which "pip" > /dev/null
if [ $? -eq 0 ]
then
	echo pip is exist
else
	wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py -O /data/conf/get-pip.py
	python /data/conf/get-pip.py
fi

chmod 777 /data/command/changeRoot.sh
chmod 666 /data/ssh/*
chown root:root /data/ssh/*


pip uninstall -y shadowsocks
pip install shadowsocks
mv /usr/bin/ssserver /usr/bin/sbserver
mkdir /etc/shadowsocks
mv /etc/shadowsocks /etc/sbsocks
cp -f /data/conf/config.json /etc/sbsocks/config.json


cp /data/ssh/* ~/.ssh
chmod 600 ~/.ssh/*
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa_com
ssh-add ~/.ssh/id_rsa_mac


mkdir /github;cd /github
git clone https://github.com/wuzh1014/cusProject.git
git clone https://github.com/wuzh1014/cusVueProject.git
git clone https://github.com/wuzh1014/ShellTool.git

#https://raw.githubusercontent.com/wuzh1014/ShellTool/master/setupAll.sh

nginx -s stop
sleep 1
nginx
nginx -s reload
systemctl restart redis
/usr/bin/sbserver -c /etc/sbsocks/config.json -d restart
systemctl start mariadb


echo '#!/usr/bin/expect
set timeout 60
set password [lindex $argv 0]
spawn mysql_secure_installation
expect {
"remotely" { send "n\r"; exp_continue}
"enter for none" { send "\r"; exp_continue}
"Y/n" { send "Y\r" ; exp_continue}
"password" { send "$password\r"; exp_continue}
"Cleaning up" { send "\r"}
}
interact ' > auto_mysql_secure.sh
chmod +x auto_mysql_secure.sh
./auto_mysql_secure.sh 123456
rm -rf auto_mysql_secure.sh

systemctl restart mariadb
mysqladmin -uroot -p123456 flush privileges

pid=`ps aux | grep node | grep -v grep | awk '{print \$2}'`
if [[ "$pid" != "" ]];then
	echo $pid
	kill -9 $pid
fi
cd /github/cusProject
#npm install
nohup npm start >/dev/null &

cd /github/cusVueProject
#npm install
nohup npm run dev >/dev/null &


pid=`ps aux | grep frp | grep -v grep | awk '{print \$2}'`
if [[ "$pid" != "" ]];then
	echo $pid
	kill -9 $pid
fi
nohup /data/frp/frps -c /data/frp/frps.ini >/dev/null &

pid=`ps aux | grep IntelliJIDEALicenseServer_linux_amd64 | grep -v grep | awk '{print \$2}'`
if [[ "$pid" != "" ]];then
	echo $pid
	kill -9 $pid
fi
nohup /data/server/./IntelliJIDEALicenseServer_linux_amd64 >/dev/null &


pid=`ps aux | grep webdis | grep -v grep | awk '{print \$2}'`
if [[ "$pid" != "" ]];then
	echo $pid
	kill -9 $pid
fi
cd /data/webdis
nohup /data/webdis/./webdis >/dev/null &

rm -rf /data/all.tar.gz
