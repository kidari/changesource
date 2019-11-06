#!/bin/sh

# echo "==================================="
# echo "please choose the source:"
# echo "  _tuna_please input 1"
# echo "  _ali_ please input 2"
# echo "  _163_ please input 3"
# echo "==================================="
# read SourceIndex

# if [ -z $SystemIndex ];then
#     echo "!!!!!error input!!!!!"
#     exit
#  else
#     index=`echo "$SourceIndex*1" | bc `
#    if [ $index -eq 2 ];then
# 	echo 222
#        Source=ali
#    elif [ $index -eq 1 ];then
# 	echo 111
#        Source=tuna   
#    elif [ $index -eq 3 ];then  
#        Source=163 
#     fi
# fi
Source=tuna
echo "======source:$Source====="
gitversion=2.24.0
echo "======git-version:$gitversion====="
dockercomposeversion=1.25.0-rc4
echo "======docker-compose-version:$dockercomposeversion====="
echo "==================================="
echo "Please Choose OS"
echo "  ubuntu18.04 please input 1"
echo "  centos7 please input 2"
echo "  raspbianbuster please input 3"
echo "==================================="
read SystemIndex

if [ -z $SystemIndex ];then
    echo "error input"
    exit
 else
    index=`echo "$SystemIndex*1" | bc `
   if [ $index -eq 1 ];then
       System=ubuntu18.04
       filename="source_${Source}_${System}.list"
       ubuntu
   elif [ $index -eq 2 ];then
       System=centos7
       filename="source_${Source}_${System}.list"
       centos7  
   elif [ $index -eq 3 ];then  
       System=raspbianbuster
       filename="source_${Source}_${System}.list"
       exterfilename="source_${Source}_${System}.list.raspi"
       raspbian
    fi
fi
exterclean


ubuntu(){
#如果你之前安装过 docker，请先删掉 
sudo apt-get remove -y docker docker-engine docker.io
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#安装最新git
echo "=====prepare install git====="
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get -y install git
sudo apt-get -fy install
sudo apt-get -y install git
echo "=====install completed====="

#获取更新源文件
getchangesourcedocument
echo "=====copy old sources list====="
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo "=====change sources list====="
sudo cp $filename /etc/apt/sources.list
#添加软件仓库
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
echo "=====update source====="
sudo apt-get -y update
echo "=====fix software====="
sudo apt-get -fy install
echo "=====update software====="
sudo apt-get -y upgrade

sudo apt-get install -y docker-ce
curl -L https://github.com/docker/compose/releases/download/${dockercomposeversion}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
sudo cp docker_daemon.json /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker
}


centos(){
#如果你之前安装过 docker，请先删掉    
sudo yum remove -y docker docker-common docker-selinux docker-engine
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

#安装最新git
echo "=====prepare install git====="
sudo yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel asciidoc gcc perl-ExtUtils-MakeMaker
sudo yum -y remove  git
cd /usr/local/
wget https://www.kernel.org/pub/software/scm/git/git-${gitversion}.tar.xz
tar -vxf git-${gitversion}.tar.xz
cd git-${gitversion}
make prefix=/usr/local/git all
make prefix=/usr/local/git install
sudo echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/profile
source /etc/profile
cd ..
sudo rm -rf git-${gitversion}
echo "=====install completed====="
#获取更新源文件
getchangesourcedocument
echo "=====copy old sources list====="
sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
echo "=====change sources list====="
sudo cp $filename /etc/yum.repos.d/CentOS-Base.repo
echo "=====update source====="
#添加软件仓库
wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
sudo sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo

sudo yum makecache
echo "=====update software====="
sudo yum upgrade -y

sudo yum install -y docker-ce
curl -L https://github.com/docker/compose/releases/download/${dockercomposeversion}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

}

raspbian(){
#如果你之前安装过 docker，请先删掉 
sudo apt-get remove -y docker docker-engine docker.io
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#安装最新git
echo "=====prepare install git====="
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get -y install git
sudo apt-get -fy install
sudo apt-get -y install git
echo "=====install completed====="

#获取更新源文件
getchangesourcedocument
echo "=====copy old sources list====="
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo "=====change sources list====="
sudo cp $filename /etc/apt/sources.list
echo "=====copy old sources list====="
sudo cp /etc/apt/sources.list.d/raspi.list /etc/apt/sources.list.d/raspi.list.bak
echo "=====change sources list====="
sudo cp $exterfilename /etc/apt/sources.list.d/raspi.list
#添加软件仓库
echo "deb [arch=armhf] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
     $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

echo "=====update source====="
sudo apt-get -y update
echo "=====fix software====="
sudo apt-get -fy install
echo "=====update software====="
sudo apt-get -y upgrade

sudo apt-get -y install docker-ce
}

getchangesourcedocument(){
echo "=====starting upload source document====="
git clone https://github.com/kidari/changesource
cd changesource
ls
}

exterclean(){
echo "=====clean exter-document====="
cd ..
sudo rm -rf changesource
echo "=====exter-document already clean====="
}

