#! /bin/bash
#
# centos 7
host=$1
port=$2
password=$3
yum install -y nginx redis git screen mysql npm golang sshpass wget libevent
sshpass -p $password ssh root@$host -o GSSAPIAuthentication=no "cp /etc/nginx/nginx.conf /data/conf;cp /etc/sbsocks/config.json /data/conf;tar -czPf /data/all.tar.gz /data/*;"

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


pip uninstall -y shadowsocks
pip install shadowsocks
mv /usr/bin/ssserver /usr/bin/sbserver
mkdir /etc/shadowsocks
mv /etc/shadowsocks /etc/sbsocks
cp -f /data/conf/config.json /etc/sbsocks/config.json

cp /data/ssh/* ~/.ssh

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
#flush privileges

pid=`ps aux | grep node | grep -v grep | awk '{print \$2}'`
if [[ "$pid" != "" ]];then
	echo $pid
	kill -9 $pid
fi
cd /github/cusProject
npm install
nohup npm start >/dev/null &

cd /github/cusVueProject
npm install
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

# rm -rf /data/all.tar.gz
