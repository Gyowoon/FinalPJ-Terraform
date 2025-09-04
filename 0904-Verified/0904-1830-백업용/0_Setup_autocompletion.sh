# USE `source <.sh> THEN source ~/.bashrc`
#!/bin/bash


export PS1="\[\e[1;34m\][\u@\h \w]\\$ \[\e[0m\]"

# =============================================================================
# Auto-completion setup script for Amazon Linux 2023 (Fixed)
# =============================================================================

# Detect if script is being sourced or executed
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -eq 0 ]]; then
  # Only enable errexit when executed, not sourced
  set -e
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored INFO
print_status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to print colored WARNING
print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to print colored ERROR
print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 1. Install bash-completion package
# =============================================================================
print_status "Installing bash-completion package..."
if command -v dnf &>/dev/null; then
  sudo dnf install -y bash-completion
elif command -v yum &>/dev/null; then
  sudo yum install -y bash-completion
else
  print_error "Neither dnf nor yum found. Please install bash-completion manually."
  exit 1
fi

# =============================================================================
# 2. Backup existing .bashrc
# =============================================================================
print_status "Creating backup of ~/.bashrc..."
if [ -f ~/.bashrc ]; then
  cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
  print_status "Backup created"
fi

# =============================================================================
# 3. Ensure bash-completion is loaded in .bashrc
# =============================================================================
print_status "Configuring bash-completion in .bashrc..."
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
  print_status "bash-completion already configured"
fi

# =============================================================================
# Helper function to add source blocks safely
# =============================================================================
add_source_block() {
  local marker="$1"
  local block="$2"
  if ! grep -Fq "$marker" ~/.bashrc; then
    echo -e "\n$block" >> ~/.bashrc
    print_status "Added block: $marker"
  else
    print_status "Block already exists: $marker"
  fi
}

# =============================================================================
# 4. Setup Docker completion
# =============================================================================
print_status "Setting up Docker completion..."
sudo mkdir -p /etc/bash_completion.d
sudo curl -sL https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker \
  -o /etc/bash_completion.d/docker || print_warning "Docker completion download failed"
add_source_block "# Docker CLI completion" "# Docker CLI completion\nif [ -f /etc/bash_completion.d/docker ]; then\n  . /etc/bash_completion.d/docker\nfi"

# =============================================================================
# 5. Setup kubectl completion
# =============================================================================
print_status "Setting up kubectl completion..."
if command -v kubectl &>/dev/null; then
  add_source_block "# kubectl completion" "# kubectl completion\nsource <(kubectl completion bash)\nalias k=kubectl\ncomplete -o default -F __start_kubectl k"
else
  print_warning "kubectl not found. Skipping kubectl completion."
fi

# =============================================================================
# 6. Setup Helm completion
# =============================================================================
print_status "Setting up Helm completion..."
if command -v helm &>/dev/null; then
  add_source_block "# helm completion" "# helm completion\nsource <(helm completion bash)"
else
  print_warning "helm not found. Skipping Helm completion."
fi

# =============================================================================
# 7. Setup Terraform completion
# =============================================================================
print_status "Setting up Terraform completion..."
if command -v terraform &>/dev/null; then
  terraform -install-autocomplete &>/dev/null || print_warning "Terraform autocomplete install failed"
  add_source_block "# terraform alias and completion" "# terraform alias and completion\nalias tf=terraform\ncomplete -C $(which terraform) terraform\ncomplete -C $(which terraform) tf"
else
  print_warning "terraform not found. Skipping Terraform completion."
fi

# =============================================================================
# 8. Add common aliases
# =============================================================================
print_status "Adding useful aliases..."
add_source_block "# DevOps aliases" "# DevOps aliases\nalias k=kubectl\nalias tf=terraform\nalias d=docker\nalias dc='docker-compose'\n# Useful kubectl aliases\nalias kgp='kubectl get pods'\nalias kgs='kubectl get services'\n# Docker aliases\nalias dps='docker ps'\nalias di='docker images'\n# Terraform aliases\nalias tfi='terraform init'\nalias tfp='terraform plan'"

# =============================================================================
# Completion for aliases
# =============================================================================
print_status "Setting up completion for aliases..."
add_source_block "# Completion for aliases" "# Completion for aliases\ncomplete -F __start_kubectl k\ncomplete -C $(which terraform) tf\ncomplete -F _docker d"

# =============================================================================
# 9. Final summary
# =============================================================================
print_status "Auto-completion setup completed!"

echo "To activate changes, run: source ~/.bashrc or open a new terminal"

