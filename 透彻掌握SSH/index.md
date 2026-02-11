面向 JS 程序员的 SSH 与 GitHub Codespaces 实操指南

一、SSH 基础与密钥认证配置

1. 核心命令解析

 ssh -ND 1080 root@XXX.XXX.XXX.XXX ：通过 SSH 建立本地 socks5 代理。

-  ssh ：调用 SSH 客户端程序；
-  -N ：空操作模式，仅建立连接不执行远程命令；
-  -D 1080 ：开启动态端口转发，本地监听 1080 端口并创建 socks5 代理；
-  root@XXX.XXX.XXX.XXX ：以 root 用户名登录目标服务器（IP 为 XXX.XXX.XXX.XXX）。

2. SSH 密钥认证配置步骤（Linux/macOS）

1. 本地生成密钥对：
bash

ssh-keygen -t rsa -b 4096
 

生成  id_rsa （私钥，勿泄露）和  id_rsa.pub （公钥），默认存于  ~/.ssh/  目录。
2. 上传公钥到目标服务器：
bash

ssh-copy-id -p 端口号 用户名@服务器IP
 

默认 22 端口可省略  -p 端口号 ，首次需输入服务器密码。
3. 测试免密登录：
bash

ssh -p 端口号 用户名@服务器IP
 
4. （可选）禁用密码登录提升安全性：
- 编辑配置文件： sudo vim /etc/ssh/sshd_config ；
- 修改参数： PasswordAuthentication no 、 PubkeyAuthentication yes ；
- 重启服务：CentOS/RHEL 用  systemctl restart sshd ，Ubuntu/Debian 用  systemctl restart ssh 。

二、面向 JS 程序员的 SSH 高级用法

1. SSH 别名与自动化配置

编辑  ~/.ssh/config  文件，添加 JS 服务场景配置：

config

# 测试环境 Node 服务
Host test-node
  HostName 10.10.10.11
  User admin
  Port 2222
  IdentityFile ~/.ssh/id_rsa_test
  ForwardAgent yes

# 生产环境前端部署机
Host prod-fe
  HostName fe-deploy.example.com
  User deploy
  IdentityFile ~/.ssh/id_rsa_prod
  Compression yes
 

使用时直接通过别名登录： ssh test-node ，传输文件： scp ./dist.zip prod-fe:/var/www/fe/ 。

2. 端口转发（调试与服务访问）

- 本地端口转发（本地访问远程 Node 服务）：
bash

ssh -L 8080:localhost:3000 test-node
 

本地访问  localhost:8080  即可调试远程 3000 端口的 Node 服务。
- 远程端口转发（远程访问本地 Vue 项目）：
bash

ssh -R 9000:localhost:8080 test-node
 

远程访问  test-node:9000  可连接本地 8080 端口的 Vue 项目。

3. SSH 与 Git/CI 联动（免密拉取代码）

- 方案 1：SSH 代理转发（复用本地密钥）：
登录服务器后执行  ssh-add -l  验证，成功后可直接  git clone git@github.com:your-name/your-node-project.git 。
- 方案 2：服务器公钥配置（固定服务器）：
服务器生成密钥对后，将公钥添加到 GitHub 仓库的「Deploy keys」中。

4. 常见问题解决

- 密钥权限错误： chmod 600 ~/.ssh/id_rsa （私钥）、 chmod 644 ~/.ssh/id_rsa.pub （公钥）；
- 远程日志查看： ssh test-node "tail -f /var/log/node-app.log" ；
- 禁用 root 登录：修改  sshd_config  中  PermitRootLogin no 。

5. 辅助工具推荐

-  sshpass ：自动化脚本中免交互输入密码；
-  autossh ：自动重连 SSH 隧道；
- VS Code Remote-SSH：本地编辑调试远程 JS 项目。

三、Docker 容器与 Node 远程调试的 SSH 配置

1. Docker 容器内配置 SSH（管理 Node 服务）

- 编写  Dockerfile ：
dockerfile

FROM node:18-alpine
RUN apk add --no-cache openssh && mkdir -p /root/.ssh && chmod 700 /root/.ssh
COPY ~/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
EXPOSE 22
RUN apk add --no-cache supervisor && mkdir -p /etc/supervisor/conf.d
COPY supervisor.conf /etc/supervisor/conf.d/
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisor.conf"]
 
- 编写  supervisor.conf ：
ini

[supervisord]
nodaemon=true
[program:sshd]
command=/usr/sbin/sshd -D
autorestart=true
[program:node-app]
directory=/app
command=node server.js
autorestart=true
stdout_logfile=/var/log/node-app.log
 
- 构建并启动容器：
bash

docker build -t node-ssh:v1 .
docker run -d -p 2223:22 -v ~/your-node-project:/app --name node-app-ssh node-ssh:v1
 
- 登录容器： ssh -p 2223 root@127.0.0.1 。

2. VS Code 远程调试 Node 服务

1. 安装 Remote-SSH 插件，连接远程服务器/容器；
2. 创建  launch.json  配置：
json

{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "attach",
            "name": "Remote Debug Node App",
            "address": "localhost",
            "port": 9229,
            "localRoot": "${workspaceFolder}",
            "remoteRoot": "/app",
            "protocol": "inspector"
        }
    ]
}
 
3. 远程启动 Node 服务： node --inspect=0.0.0.0:9229 server.js ；
4. 点击 VS Code 「启动调试」，设置断点即可调试。

四、GitHub Codespaces 相关配置

1. Codespaces 部署 desktop-lite 并 SSH -X 连接

- 配置  devcontainer.json ：
json

{
  "name": "GitHub Codespaces with Desktop-Lite",
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  "features": {
    "ghcr.io/devcontainers/features/desktop-lite:1": {
      "version": "latest",
      "noVncPort": "6080",
      "password": "codespaces"
    }
  },
  "hostRequirements": {
    "cpus": 2,
    "memory": "4gb"
  },
  "remoteUser": "vscode"
}
 
- 本地安装 GitHub CLI（gh）并登录： gh auth login ；
- 端口转发： gh codespace ssh -- -L 2222:localhost:22 你的Codespaces名称 ；
- 本地安装 X11 服务器（macOS 用 XQuartz，Windows 用 VcXsrv）；
- SSH -X 连接并启动桌面： ssh -X -p 2222 vscode@localhost ，执行  startxfce4 。

2. desktop-lite 的 VNC 连接与密码修改

- 配置  devcontainer.json  开启 VNC 端口：
json

{
    "features": {
        "ghcr.io/devcontainers/features/desktop-lite:1": {}
    },
    "forwardPorts": [5901],
    "portsAttributes": {
        "5901": {
            "label": "vnc desktop"
        }
    }
}
 
- 修改密码：Codespaces 终端执行  vncpasswd ，按提示输入新密码，无需重启服务即可生效；
- 本地连接：VNC 客户端输入  localhost:5901 ，用新密码登录。

3. Codespaces 部署 Windows 容器并本地桌面连接
- 创建  docker-compose.yml ：
```yaml
version: '3'
services:
  windows:
    image: dockurr/windows:11
    container_name: codespaces-windows
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - "8080:8080"
      - "5900:5900"
    environment:
      - RAM_SIZE=4G
      - CPU_CORES=2
      - DISK_SIZE=64G
      - AUTOSTART=1
      - VNC_PASSWORD=your-new-password
    restart: unless-stopped

```
- 启动容器： docker-compose up -d ；
- Codespaces 端口转发：「Ports」标签添加 5900 端口并设为 Public；
- 本地连接：VNC 客户端输入  localhost:5900 ，用自定义密码登录。

4. 镜像系统说明

 mcr.microsoft.com/devcontainers/dotnet:10.0-noble ：基于 Ubuntu 24.04（代号 Noble Numbat） 构建，预装 .NET 10.0 SDK，适用于 .NET 开发的 DevContainer 环境。
