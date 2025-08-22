# 开发工具自动化脚本集合

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

一个实用的Linux/Unix系统自动化脚本和工具集合。这些脚本旨在简化常见的开发和部署任务，提供一键式安装体验。

## 📁 项目结构

```
tools/
├── scripts/                      # 各种安装脚本
│   ├── install_docker.sh         # Docker & Docker Compose 安装器
│   ├── install_go.sh             # Go 编程语言安装器
│   ├── install_nodejs.sh         # Node.js & npm 安装器
│   └── README.md                 # 脚本说明文档
├── dockerfiles/                  # Docker 镜像构建文件
├── dotfiles/                     # 配置文件模板
└── README.md                     # 本文件
```

## 🚀 快速开始

### 系统要求

- Linux/Unix 系统 (Ubuntu, CentOS, Debian 等)
- 已安装 `curl` 或 `wget`
- 具有 `sudo` 权限

### 安装脚本

所有脚本都设计为自包含的，只需要最少的依赖。

## 📋 可用工具

### 🐳 Docker 安装脚本

**文件：** `scripts/install_docker.sh`

一键安装 Docker 和 Docker Compose，具有智能地区检测功能。

#### 特性

- ✅ **多平台支持**：Debian/Ubuntu、CentOS/RHEL/Fedora
- ✅ **智能地区检测**：中国用户自动使用阿里云镜像
- ✅ **Docker CE 安装**：来自官方仓库的最新稳定版本
- ✅ **Docker Compose 支持**：支持插件版和独立版
- ✅ **用户权限设置**：自动配置 docker 用户组
- ✅ **安装验证**：内置测试和验证

#### 使用方法

```bash
# 赋予执行权限
chmod +x scripts/install_docker.sh

# 运行安装
./scripts/install_docker.sh
```

#### 安装流程

1. 检测系统环境和地区
2. 更新包管理器并安装依赖
3. 添加 Docker 官方仓库（中国用户使用阿里云镜像）
4. 安装 Docker CE 和 Docker Compose
5. 配置优化的守护进程设置
6. 设置用户权限
7. 使用测试容器验证安装

---

### 🔧 Go 安装脚本

**文件：** `scripts/install_go.sh`

灵活的 Go 编程语言安装器，支持版本控制和智能源选择。

#### 特性

- ✅ **版本灵活性**：安装最新版本或指定确切版本
- ✅ **架构检测**：支持 amd64、arm64、386、armv6l
- ✅ **平台支持**：Linux 和 macOS
- ✅ **智能下载**：中国用户使用阿里云镜像，全球用户使用官方源
- ✅ **环境设置**：自动配置 GOROOT、GOPATH 和 PATH
- ✅ **安装验证**：内置示例程序测试

#### 使用方法

```bash
# 赋予执行权限
chmod +x scripts/install_go.sh

# 安装最新版本
./scripts/install_go.sh

# 安装指定版本
./scripts/install_go.sh 1.21.5

# 使用自定义目录安装
./scripts/install_go.sh --dir /opt

# 强制重新安装
./scripts/install_go.sh 1.21.5 --force

# 显示帮助
./scripts/install_go.sh --help
```

#### 命令行选项

| 选项 | 描述 | 示例 |
|------|------|------|
| `VERSION` | 要安装的 Go 版本 | `1.21.5`, `1.20.10` |
| `--dir DIR` | 安装目录 | `--dir /opt` |
| `--force` | 强制重新安装现有版本 | `--force` |
| `--help, -h` | 显示帮助信息 | `--help` |

#### 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `GO_INSTALL_DIR` | 安装目录 | `/usr/local` |

---

### 🟢 Node.js 安装脚本

**文件：** `scripts/install_nodejs.sh`

使用 NVM 管理的 Node.js 和 npm 安装器，支持多版本管理。

#### 特性

- ✅ **NVM 管理**：使用 Node Version Manager 管理多个 Node.js 版本
- ✅ **版本控制**：安装最新 LTS 版本或指定确切版本
- ✅ **智能镜像**：中国用户自动使用 npmmirror 镜像加速
- ✅ **环境配置**：自动配置 NVM、npm 环境变量
- ✅ **npm 优化**：配置全局包目录，避免权限问题
- ✅ **安装验证**：内置功能测试

#### 使用方法

```bash
# 赋予执行权限
chmod +x scripts/install_nodejs.sh

# 安装最新 LTS 版本
./scripts/install_nodejs.sh

# 安装指定版本
./scripts/install_nodejs.sh 18.19.0

# 强制重新安装
./scripts/install_nodejs.sh 20.10.0 --force

# 显示帮助
./scripts/install_nodejs.sh --help
```

#### 命令行选项

| 选项 | 描述 | 示例 |
|------|------|------|
| `VERSION` | 要安装的 Node.js 版本 | `18.19.0`, `20.10.0` |
| `--lts` | 安装最新 LTS 版本 | `--lts` |
| `--force` | 强制重新安装现有版本 | `--force` |
| `--no-npm-config` | 跳过 npm 配置优化 | `--no-npm-config` |

#### NVM 常用命令

```bash
nvm list                    # 列出已安装的 Node.js 版本
nvm install <version>       # 安装指定版本
nvm use <version>           # 切换到指定版本
nvm alias default <version> # 设置默认版本
npm install -g <package>    # 安装全局包
```

---

## 🌐 地区优化

所有脚本都包含智能地区检测，以获得最佳下载性能：

### 检测方法

1. **时区检测**：检查 Asia/Shanghai、Asia/Chongqing
2. **语言环境检测**：查找 zh_CN 语言设置
3. **连通性测试**：测试对官方源的访问

### 镜像源

| 地区 | Docker 源 | Go 源 | Node.js 源 |
|------|-----------|-------|------------|
| 中国 | mirrors.aliyun.com/docker-ce | mirrors.aliyun.com/golang | npmmirror.com |
| 全球 | download.docker.com | golang.org/dl | nodejs.org |

## 🛠️ 高级配置

### Docker 配置

Docker 安装器创建优化的 `daemon.json`：

```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true
}
```

### Go 环境设置

Go 安装器配置这些环境变量：

```bash
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
```

### Node.js 环境设置

Node.js 安装器配置 NVM 和 npm：

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PATH="$HOME/.npm-global/bin:$PATH"

# 中国用户额外配置
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
npm config set registry https://registry.npmmirror.com/
```

## 🔍 故障排除

### 常见问题

1. **权限被拒绝**
   ```bash
   chmod +x script_name.sh
   ```

2. **缺少 curl/wget**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install curl
   
   # CentOS/RHEL
   sudo yum install curl
   ```

3. **Docker 组权限问题**
   ```bash
   # 注销并重新登录，或者：
   newgrp docker
   ```

4. **Go PATH 问题**
   ```bash
   source ~/.bashrc
   # 或
   source ~/.zshrc
   ```

5. **Node.js/NVM 问题**
   ```bash
   # 重启终端或重新加载配置
   source ~/.bashrc
   
   # 检查 NVM 安装
   nvm --version
   ```

### 日志和调试

所有脚本都提供彩色输出以便于调试：
- 🔵 **INFO**：一般信息
- 🟢 **SUCCESS**：成功操作
- 🟡 **WARNING**：非关键问题
- 🔴 **ERROR**：关键错误

## 🤝 贡献

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m '添加某个很棒的功能'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

### 贡献指南

- 遵循现有的代码风格和约定
- 添加适当的错误处理和日志记录
- 在多个发行版上测试脚本
- 为新功能更新文档
- 确保地区优化正常工作

## 📝 许可证

本项目根据 MIT 许可证授权 - 详见 [LICENSE](LICENSE) 文件。

## 👥 作者

- **zdev0x** - *初始工作*

## 🙏 致谢

- Docker 团队提供的优秀文档
- Go 团队提供的简洁安装包
- 阿里云提供可靠的镜像服务
- npmmirror 提供的 Node.js 镜像服务
- 社区贡献者和测试者

## 📞 支持

如果您遇到任何问题或有疑问：

1. 查看 [故障排除](#-故障排除) 部分
2. 检查脚本输出中的错误信息
3. 提交包含详细错误信息的 issue
4. 包含您的系统信息和脚本版本

## 🎯 未来计划

- [ ] Python 安装脚本
- [ ] Java 安装脚本
- [ ] Kubernetes 工具安装脚本
- [ ] 开发环境一键配置脚本
- [ ] 更多操作系统支持

---

**用 ❤️ 为开发者社区制作**