# Tools Collection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

A collection of useful automation scripts and tools for Linux/Unix systems. These scripts are designed to simplify common development and deployment tasks.

## 📁 Project Structure

```
tools/
├── bash/           # Shell scripts for various installations
│   ├── install_docker.sh     # Docker & Docker Compose installer
│   └── install_go.sh         # Go programming language installer
├── docker/         # Docker-related configurations
└── README.md       # This file
```

## 🚀 Quick Start

### Prerequisites

- Linux/Unix system (Ubuntu, CentOS, Debian, etc.)
- `curl` or `wget` installed
- `sudo` privileges for system installations

### Installation Scripts

All scripts are designed to be self-contained and require minimal dependencies.

## 📋 Available Tools

### 🐳 Docker Installation Script

**File:** `bash/install_docker.sh`

One-click installation script for Docker and Docker Compose with intelligent region detection.

#### Features

- ✅ **Multi-platform support**: Debian/Ubuntu, CentOS/RHEL/Fedora
- ✅ **Smart region detection**: Automatically uses Aliyun mirrors for China users
- ✅ **Docker CE installation**: Latest stable version from official repositories
- ✅ **Docker Compose support**: Both plugin and standalone versions
- ✅ **User permission setup**: Automatic docker group configuration
- ✅ **Installation verification**: Built-in testing and validation

#### Usage

```bash
# Make script executable
chmod +x bash/install_docker.sh

# Run installation
./bash/install_docker.sh
```

#### What it does

1. Detects system environment and region
2. Updates package manager and installs dependencies
3. Adds Docker official repositories (or Aliyun mirrors for China)
4. Installs Docker CE and Docker Compose
5. Configures daemon with optimized settings
6. Sets up user permissions
7. Verifies installation with test container

---

### 🔧 Go Installation Script

**File:** `bash/install_go.sh`

Flexible Go programming language installer with version control and intelligent source selection.

#### Features

- ✅ **Version flexibility**: Install latest version or specify exact version
- ✅ **Architecture detection**: Supports amd64, arm64, 386, armv6l
- ✅ **Platform support**: Linux and macOS
- ✅ **Smart downloads**: Aliyun mirrors for China, official source globally
- ✅ **Environment setup**: Automatic GOROOT, GOPATH, and PATH configuration
- ✅ **Installation verification**: Built-in testing with sample program

#### Usage

```bash
# Make script executable
chmod +x bash/install_go.sh

# Install latest version
./bash/install_go.sh

# Install specific version
./bash/install_go.sh 1.21.5

# Install with custom directory
./bash/install_go.sh --dir /opt

# Force reinstall
./bash/install_go.sh 1.21.5 --force

# Show help
./bash/install_go.sh --help
```

#### Command Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `VERSION` | Go version to install | `1.21.5`, `1.20.10` |
| `--dir DIR` | Installation directory | `--dir /opt` |
| `--force` | Force reinstall existing version | `--force` |
| `--help, -h` | Show help message | `--help` |

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GO_INSTALL_DIR` | Installation directory | `/usr/local` |

---

## 🌐 Regional Optimization

Both scripts include intelligent region detection for optimal download performance:

### Detection Methods

1. **Timezone detection**: Checks for Asia/Shanghai, Asia/Chongqing
2. **Locale detection**: Looks for zh_CN language settings
3. **Connectivity testing**: Tests access to official sources

### Mirror Sources

| Region | Docker Source | Go Source |
|--------|---------------|-----------|
| China | mirrors.aliyun.com/docker-ce | mirrors.aliyun.com/golang |
| Global | download.docker.com | golang.org/dl |

## 🛠️ Advanced Configuration

### Docker Configuration

The Docker installer creates an optimized `daemon.json`:

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

### Go Environment Setup

The Go installer configures these environment variables:

```bash
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
```

## 🔍 Troubleshooting

### Common Issues

1. **Permission denied**
   ```bash
   chmod +x script_name.sh
   ```

2. **Missing curl/wget**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install curl
   
   # CentOS/RHEL
   sudo yum install curl
   ```

3. **Docker group permissions**
   ```bash
   # Logout and login again, or:
   newgrp docker
   ```

4. **Go PATH issues**
   ```bash
   source ~/.bashrc
   # or
   source ~/.zshrc
   ```

### Logs and Debugging

Both scripts provide colored output for easy debugging:
- 🔵 **INFO**: General information
- 🟢 **SUCCESS**: Successful operations
- 🟡 **WARNING**: Non-critical issues
- 🔴 **ERROR**: Critical failures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style and conventions
- Add proper error handling and logging
- Test scripts on multiple distributions
- Update documentation for new features
- Ensure regional optimization works correctly

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **zdev0x** - *Initial work*

## 🙏 Acknowledgments

- Docker team for excellent documentation
- Go team for clean installation packages
- Aliyun for providing reliable mirror services
- Community contributors and testers

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review script output for error messages
3. Open an issue with detailed error information
4. Include your system information and script version

---

**Made with ❤️ for the developer community**