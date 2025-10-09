# Ansible Infrastructure Documentation

This directory contains all Ansible-related files for infrastructure automation.

## Directory Structure

- `inventory/`: Host inventory files for different environments
- `group_vars/`: Environment-specific variables
- `playbooks/`: Ansible playbooks for various tasks
- `roles/`: Ansible roles (to be added as needed)
- `templates/`: Jinja2 templates for configuration files
- `host_vars/`: Host-specific variables (optional)

## Playbooks

### main.yml
Main orchestration playbook that runs all infrastructure setup tasks.

**Usage:**
```bash
ansible-playbook -i inventory/dev playbooks/main.yml -e "environment=dev"
ansible-playbook -i inventory/stage playbooks/main.yml -e "environment=stage"
ansible-playbook -i inventory/prod playbooks/main.yml -e "environment=prod"
```

### install-docker.yml
Installs and configures Docker on all target servers.

**Tasks:**
- Update system packages
- Add Docker repository
- Install Docker and related packages
- Configure Docker daemon
- Add users to docker group
- Enable Docker service

**Usage:**
```bash
ansible-playbook -i inventory/dev playbooks/install-docker.yml
```

### setup-kubernetes.yml
Sets up a Kubernetes cluster with one master and multiple worker nodes.

**Tasks:**
- Disable swap and configure kernel parameters
- Install Kubernetes packages (kubelet, kubeadm, kubectl)
- Initialize Kubernetes master
- Install CNI plugin (Flannel)
- Join worker nodes to the cluster

**Usage:**
```bash
ansible-playbook -i inventory/dev playbooks/setup-kubernetes.yml
```

## Inventory Files

Inventory files define the target hosts for each environment.

### Structure
```ini
[group_name]
hostname ansible_host=IP ansible_user=USER ansible_ssh_private_key_file=PATH

[parent_group:children]
group1
group2
```

### Groups
- `dev_servers`: Development environment servers
- `stage_servers`: Staging environment servers
- `prod_servers`: Production environment servers
- `kubernetes_master`: Kubernetes master node(s)
- `kubernetes_workers`: Kubernetes worker nodes

## Variables

### Group Variables (group_vars/)

Environment-specific variables stored in `group_vars/{environment}.yml`:

**Common Variables:**
- `environment`: Environment name (dev/stage/prod)
- `domain`: Domain name for the environment
- `docker_version`: Docker version to install
- `kubernetes_version`: Kubernetes version to install
- `db_host`, `db_port`, `db_name`, `db_user`: Database configuration
- `redis_host`, `redis_port`: Redis configuration
- `app_replicas`: Number of application replicas
- `app_cpu_limit`, `app_memory_limit`: Resource limits
- `log_level`: Application log level
- `enable_monitoring`: Enable/disable monitoring

### Overriding Variables

Override variables at runtime:
```bash
ansible-playbook -i inventory/dev playbooks/main.yml -e "app_replicas=5"
```

## Templates

Templates use Jinja2 syntax and are rendered with variables from inventory and group_vars.

### app-config.j2
Application configuration template that generates environment-specific config files.

**Variables used:**
- All variables from group_vars
- Ansible facts (ansible_hostname, ansible_distribution, etc.)

## Best Practices

### 1. SSH Key Management
- Store SSH keys securely outside the repository
- Use different keys for each environment
- Never commit private keys to Git

### 2. Secret Management
- Use Ansible Vault for sensitive data:
```bash
ansible-vault create group_vars/prod_secrets.yml
ansible-vault edit group_vars/prod_secrets.yml
```
- Run playbooks with vault password:
```bash
ansible-playbook -i inventory/prod playbooks/main.yml --ask-vault-pass
```

### 3. Testing
Test playbooks with `--check` flag (dry-run):
```bash
ansible-playbook -i inventory/dev playbooks/main.yml --check
```

### 4. Idempotency
All playbooks are designed to be idempotent - running them multiple times produces the same result.

### 5. Error Handling
Use tags for selective execution:
```bash
ansible-playbook -i inventory/dev playbooks/main.yml --tags docker
```

## Common Tasks

### Update all servers
```bash
ansible all -i inventory/dev -m apt -a "update_cache=yes upgrade=dist" --become
```

### Check connectivity
```bash
ansible all -i inventory/dev -m ping
```

### Gather facts
```bash
ansible all -i inventory/dev -m setup
```

### Run ad-hoc commands
```bash
ansible all -i inventory/dev -a "docker --version"
ansible kubernetes_master -i inventory/dev -a "kubectl get nodes"
```

## Troubleshooting

### Connection Refused
- Verify SSH key permissions (should be 600)
- Check if SSH service is running on target hosts
- Verify firewall rules allow SSH connections

### Permission Denied
- Ensure user has sudo privileges
- Use `--become` flag for privilege escalation
- Check sudoers configuration

### Module Not Found
- Install required Python packages on target hosts:
```bash
ansible all -i inventory/dev -m raw -a "apt-get install -y python3 python3-apt"
```

### Playbook Hangs
- Increase timeout values in ansible.cfg
- Use `-vvv` flag for verbose output
- Check for prompts that need interaction

## Extending the Infrastructure

### Adding New Roles
```bash
cd ansible
ansible-galaxy init roles/new_role
```

### Adding New Playbooks
1. Create playbook in `playbooks/` directory
2. Follow existing playbook structure
3. Import in `main.yml` if needed
4. Document in this README

### Adding New Variables
1. Add to appropriate `group_vars/{environment}.yml`
2. Update templates if needed
3. Document variable purpose and default values

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Docker Installation Guide](https://docs.docker.com/engine/install/)
- [Kubernetes Setup](https://kubernetes.io/docs/setup/)
