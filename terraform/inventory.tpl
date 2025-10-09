# Inventario generado automáticamente por Terraform
# Generado el: ${timestamp()}

[dev_vms]
%{ for ip in dev_ips ~}
${ip} ansible_user=root ansible_ssh_private_key_file=${ssh_key_path}
%{ endfor ~}

[stage_k8s_master]
${stage_master} ansible_user=root ansible_ssh_private_key_file=${ssh_key_path}

[stage_k8s_workers]
%{ for ip in stage_workers ~}
${ip} ansible_user=root ansible_ssh_private_key_file=${ssh_key_path}
%{ endfor ~}

[prod_vms]
# Agregar VMs de producción cuando sean necesarias
# 0.0.0.0 ansible_user=root ansible_ssh_private_key_file=${ssh_key_path}

# Grupos para compatibilidad con playbooks existentes
[k8s_master:children]
stage_k8s_master

[k8s_workers:children]
stage_k8s_workers

# Grupos lógicos para despliegues por ambiente
[all_dev_infra:children]
dev_vms

[all_stage_infra:children]
stage_k8s_master
stage_k8s_workers

[all_prod_infra:children]
prod_vms
