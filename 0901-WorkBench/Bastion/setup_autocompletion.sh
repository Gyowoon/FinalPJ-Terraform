#!/bin/bash

# =============================================================================
# Auto-completion setup script for Amazon Linux 2023
# This script sets up bash auto-completion for docker, helm, kubectl, terraform
# =============================================================================

set -e  # Exit on any error

echo "🚀 Setting up auto-completion for docker, helm, kubectl, terraform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "This script should not be run as root for user-specific configuration"
   print_warning "Run without sudo for user installation"
fi

# =============================================================================
# 1. Install bash-completion package
# =============================================================================
print_status "Installing bash-completion package..."

if command -v dnf &> /dev/null; then
    # Amazon Linux 2023 uses dnf
    sudo dnf install -y bash-completion
elif command -v yum &> /dev/null; then
    # Fallback to yum
    sudo yum install -y bash-completion
else
    print_error "Neither dnf nor yum found. Please install bash-completion manually."
    exit 1
fi

# =============================================================================
# 2. Create backup of existing .bashrc
# =============================================================================
print_status "Creating backup of .bashrc..."
if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backup created: ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

# =============================================================================
# 3. Ensure bash-completion is loaded in .bashrc
# =============================================================================
print_status "Configuring bash-completion in .bashrc..."

# Check if bash-completion is already sourced
if ! grep -q "bash_completion" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Enable bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
EOF
    print_status "Added bash-completion sourcing to .bashrc"
else
    print_status "bash-completion already configured in .bashrc"
fi

# =============================================================================
# 4. Setup Docker completion
# =============================================================================
print_status "Setting up Docker completion..."

# 공식 completion 스크립트 다운로드
sudo mkdir -p /etc/bash_completion.d
sudo curl -sL https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker \
     -o /etc/bash_completion.d/docker

# bash-completion이 항상 동작하도록 ~/.bashrc에 보장
if ! grep -qe 'bash_completion' ~/.bashrc; then
  echo "
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
" >> ~/.bashrc
fi

# docker-completion 스크립트를 ~/.bashrc에서 source
if ! grep -qe '/etc/bash_completion.d/docker' ~/.bashrc; then
  echo "
# Docker CLI completion
if [ -f /etc/bash_completion.d/docker ]; then
  . /etc/bash_completion.d/docker
fi
" >> ~/.bashrc
fi

# =============================================================================
# 5. Setup kubectl completion
# =============================================================================
print_status "Setting up kubectl completion..."

if command -v kubectl &> /dev/null; then
    # Add kubectl completion to .bashrc
    if ! grep -q "kubectl completion bash" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# kubectl completion
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
        print_status "✅ kubectl completion configured"
    else
        print_status "kubectl completion already configured"
    fi
else
    print_warning "kubectl not found. Skipping kubectl completion setup."
fi

# =============================================================================
# 6. Setup Helm completion
# =============================================================================
print_status "Setting up Helm completion..."

if command -v helm &> /dev/null; then
    # Add helm completion to .bashrc
    if ! grep -q "helm completion bash" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# helm completion
source <(helm completion bash)
EOF
        print_status "✅ Helm completion configured"
    else
        print_status "Helm completion already configured"
    fi
else
    print_warning "Helm not found. Skipping Helm completion setup."
fi

# =============================================================================
# 7. Setup Terraform completion
# =============================================================================
print_status "Setting up Terraform completion..."

if command -v terraform &> /dev/null; then
    # Install terraform autocompletion
    terraform -install-autocomplete 2>/dev/null || {
        print_warning "Terraform autocomplete installation failed, trying manual setup..."

        # Manual setup as fallback
        if ! grep -q "terraform completion bash" ~/.bashrc; then
            cat >> ~/.bashrc << 'EOF'

# terraform completion
complete -C $(which terraform) terraform
alias tf=terraform
complete -C $(which terraform) tf
EOF
            print_status "✅ Terraform completion configured (manual)"
        fi
    }

    # Add alias for terraform
    if ! grep -q "alias tf=terraform" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# terraform alias
alias tf=terraform
complete -C $(which terraform) tf
EOF
    fi

    print_status "✅ Terraform completion configured"
else
    print_warning "Terraform not found. Skipping Terraform completion setup."
fi

# =============================================================================
# 8. Add common aliases and additional configuration
# =============================================================================
print_status "Adding useful aliases..."

if ! grep -q "# DevOps aliases" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# DevOps aliases
alias k=kubectl
alias tf=terraform
alias d=docker
alias dc='docker-compose'

# Useful kubectl aliases
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'

# Terraform aliases
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
EOF
    print_status "✅ DevOps aliases added"
fi

# =============================================================================
# 9. Setup completion for aliases
# =============================================================================
print_status "Setting up completion for aliases..."

if ! grep -q "# Completion for aliases" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Completion for aliases
complete -F __start_kubectl k
complete -C $(which terraform) tf
complete -F _docker d
EOF
    print_status "✅ Alias completion configured"
fi

# =============================================================================
# 10. Final setup and instructions
# =============================================================================
print_status "Auto-completion setup completed!"
echo ""
echo "==============================================================================="
echo "🎉 Setup Summary:"
echo "==============================================================================="
echo "✅ bash-completion package installed"
echo "✅ Docker completion configured"
echo "✅ kubectl completion configured" 
echo "✅ Helm completion configured"
echo "✅ Terraform completion configured"
echo "✅ Useful aliases added"
echo ""
echo "📝 To activate the changes:"
echo "   source ~/.bashrc"
echo "   OR"
echo "   Open a new terminal session"
echo ""
echo "🔧 Available aliases:"
echo "   k     = kubectl"
echo "   tf    = terraform" 
echo "   d     = docker"
echo "   dc    = docker-compose"
echo "   kgp   = kubectl get pods"
echo "   kgs   = kubectl get services"
echo "   tfi   = terraform init"
echo "   tfp   = terraform plan"
echo "   dps   = docker ps"
echo "   di    = docker images"
echo ""
echo "💡 Test completion with: k <TAB>, tf <TAB>, d <TAB>, helm <TAB>"
echo "==============================================================================="
