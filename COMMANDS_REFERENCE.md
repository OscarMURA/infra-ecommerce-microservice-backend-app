# 🔧 Comandos de Referencia Rápida

## 🎯 Terraform

### Inicialización y Validación
```bash
# Inicializar
terraform init

# Actualizar providers
terraform init -upgrade

# Validar configuración
terraform validate

# Formatear código
terraform fmt -recursive

# Ver versión
terraform version
```

### Plan y Apply
```bash
# Ver plan
terraform plan

# Guardar plan
terraform plan -out=tfplan

# Aplicar plan guardado
terraform apply tfplan

# Aplicar sin confirmación
terraform apply -auto-approve

# Aplicar con variable específica
terraform apply -var="node_count=5"
```

### Estado y Outputs
```bash
# Ver estado
terraform show

# Listar recursos
terraform state list

# Ver recurso específico
terraform state show <resource>

# Ver outputs
terraform output

# Ver output específico
terraform output cluster_name

# Output en JSON
terraform output -json
```

### Destroy
```bash
# Destruir todo
terraform destroy

# Destruir recurso específico
terraform destroy -target=<resource>

# Destruir sin confirmación (cuidado!)
terraform destroy -auto-approve
```

### Troubleshooting
```bash
# Verificar configuración
terraform validate

# Ver plan detallado
terraform plan -detailed-exitcode

# Refrescar estado
terraform refresh

# Importar recurso existente
terraform import <resource> <id>

# Remover del estado sin destruir
terraform state rm <resource>

# Debug
TF_LOG=DEBUG terraform plan
```

---

## ☸️ kubectl

### Información del Cluster
```bash
# Info del cluster
kubectl cluster-info

# Versión
kubectl version

# Ver nodos
kubectl get nodes

# Detalles de un nodo
kubectl describe node <node-name>

# Top nodes (requiere metrics-server)
kubectl top nodes

# Ver contextos
kubectl config get-contexts

# Cambiar contexto
kubectl config use-context <context>
```

### Pods
```bash
# Listar pods en namespace
kubectl get pods -n <namespace>

# Todos los namespaces
kubectl get pods -A

# Con más info
kubectl get pods -o wide

# Watch
kubectl get pods -w

# Describir pod
kubectl describe pod <pod-name> -n <namespace>

# Logs
kubectl logs <pod-name> -n <namespace>

# Logs en tiempo real
kubectl logs -f <pod-name> -n <namespace>

# Logs de contenedor específico
kubectl logs <pod-name> -c <container> -n <namespace>

# Ejecutar comando en pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Top pods
kubectl top pods -A
```

### Servicios y Deployments
```bash
# Ver servicios
kubectl get svc -A

# Ver deployments
kubectl get deployments -A

# Ver statefulsets
kubectl get statefulsets -A

# Ver daemonsets
kubectl get daemonsets -A

# Escalar deployment
kubectl scale deployment <name> --replicas=3 -n <namespace>

# Reiniciar deployment
kubectl rollout restart deployment <name> -n <namespace>

# Ver historial
kubectl rollout history deployment <name> -n <namespace>

# Rollback
kubectl rollout undo deployment <name> -n <namespace>
```

### ConfigMaps y Secrets
```bash
# Ver configmaps
kubectl get configmaps -n <namespace>

# Ver secrets
kubectl get secrets -n <namespace>

# Describir secret
kubectl describe secret <name> -n <namespace>

# Ver contenido de configmap
kubectl get configmap <name> -o yaml -n <namespace>

# Crear secret desde archivo
kubectl create secret generic <name> --from-file=<file> -n <namespace>

# Crear secret desde literal
kubectl create secret generic <name> --from-literal=key=value -n <namespace>
```

### Namespaces
```bash
# Listar namespaces
kubectl get namespaces

# Crear namespace
kubectl create namespace <name>

# Eliminar namespace (¡cuidado!)
kubectl delete namespace <name>

# Ver recursos en namespace
kubectl get all -n <namespace>
```

### Eventos y Debug
```bash
# Ver eventos
kubectl get events -A

# Eventos ordenados
kubectl get events --sort-by='.lastTimestamp' -A

# Eventos de un namespace
kubectl get events -n <namespace>

# Describir recurso
kubectl describe <resource-type> <name> -n <namespace>

# Ver recursos con problemas
kubectl get pods -A | grep -v Running

# Port forward
kubectl port-forward <pod-name> 8080:80 -n <namespace>

# Ver uso de recursos
kubectl top nodes
kubectl top pods -A
```

### Apply y Delete
```bash
# Aplicar manifiesto
kubectl apply -f <file>.yaml

# Aplicar directorio
kubectl apply -f <directory>/

# Aplicar desde URL
kubectl apply -f https://...

# Eliminar recurso
kubectl delete -f <file>.yaml

# Eliminar por tipo y nombre
kubectl delete pod <name> -n <namespace>

# Eliminar todo en namespace
kubectl delete all --all -n <namespace>

# Force delete pod
kubectl delete pod <name> -n <namespace> --grace-period=0 --force
```

---

## 🌊 DigitalOcean (doctl)

### Autenticación
```bash
# Inicializar
doctl auth init

# Listar cuentas
doctl auth list

# Cambiar cuenta
doctl auth switch --context <context>

# Info de cuenta
doctl account get
```

### Kubernetes
```bash
# Listar clusters
doctl kubernetes cluster list

# Info de cluster
doctl kubernetes cluster get <cluster-id>

# Obtener kubeconfig
doctl kubernetes cluster kubeconfig save <cluster-name>

# Ver kubeconfig
doctl kubernetes cluster kubeconfig show <cluster-name>

# Listar node pools
doctl kubernetes cluster node-pool list <cluster-id>

# Info de node pool
doctl kubernetes cluster node-pool get <cluster-id> <pool-id>

# Actualizar cluster
doctl kubernetes cluster upgrade <cluster-id>

# Versiones disponibles
doctl kubernetes options versions

# Opciones de tamaños
doctl kubernetes options sizes

# Regiones disponibles
doctl kubernetes options regions
```

### Registry
```bash
# Login al registry
doctl registry login

# Listar repositories
doctl registry repository list

# Ver tags
doctl registry repository list-tags <repository>

# Eliminar tag
doctl registry repository delete-tag <repository> <tag>
```

### Droplets y VPC
```bash
# Listar droplets
doctl compute droplet list

# Listar VPCs
doctl vpcs list

# Info de VPC
doctl vpcs get <vpc-id>
```

---

## ☁️ Google Cloud (gcloud)

### Autenticación
```bash
# Login
gcloud auth login

# Login para aplicaciones
gcloud auth application-default login

# Listar cuentas
gcloud auth list

# Revocar autenticación
gcloud auth revoke <account>
```

### Proyectos
```bash
# Listar proyectos
gcloud projects list

# Ver proyecto actual
gcloud config get-value project

# Cambiar proyecto
gcloud config set project <project-id>

# Info de proyecto
gcloud projects describe <project-id>
```

### GKE
```bash
# Listar clusters
gcloud container clusters list

# Info de cluster
gcloud container clusters describe <cluster-name> --region <region>

# Obtener credentials
gcloud container clusters get-credentials <cluster-name> --region <region>

# Crear cluster (básico)
gcloud container clusters create <name> --region <region>

# Escalar cluster
gcloud container clusters resize <name> --num-nodes 3 --region <region>

# Actualizar cluster
gcloud container clusters upgrade <name> --master --region <region>

# Eliminar cluster
gcloud container clusters delete <name> --region <region>

# Ver versiones disponibles
gcloud container get-server-config --region <region>

# Listar node pools
gcloud container node-pools list --cluster <cluster-name> --region <region>
```

### IAM
```bash
# Listar service accounts
gcloud iam service-accounts list

# Crear service account
gcloud iam service-accounts create <name>

# Crear key
gcloud iam service-accounts keys create key.json --iam-account <email>

# Agregar role
gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:<email>" \
  --role="<role>"
```

### Compute y Network
```bash
# Listar VPCs
gcloud compute networks list

# Listar subnets
gcloud compute networks subnets list

# Listar firewalls
gcloud compute firewall-rules list

# Listar regiones
gcloud compute regions list

# Listar zonas
gcloud compute zones list
```

### APIs y Servicios
```bash
# Listar APIs habilitadas
gcloud services list --enabled

# Habilitar API
gcloud services enable <api-name>

# Deshabilitar API
gcloud services disable <api-name>
```

---

## 🔄 Git

### Básicos
```bash
# Status
git status

# Add cambios
git add .
git add <file>

# Commit
git commit -m "message"

# Push
git push origin <branch>

# Pull
git pull origin <branch>

# Ver log
git log --oneline
```

### Branches
```bash
# Listar branches
git branch

# Crear branch
git branch <name>

# Cambiar branch
git checkout <name>
# o
git switch <name>

# Crear y cambiar
git checkout -b <name>
```

---

## 🐳 Docker

### Imágenes
```bash
# Listar imágenes
docker images

# Pull imagen
docker pull <image>:<tag>

# Build imagen
docker build -t <name>:<tag> .

# Tag imagen
docker tag <image> <registry>/<name>:<tag>

# Push imagen
docker push <registry>/<name>:<tag>

# Eliminar imagen
docker rmi <image>
```

### Contenedores
```bash
# Listar contenedores
docker ps
docker ps -a

# Ejecutar contenedor
docker run -d --name <name> <image>

# Logs
docker logs <container>
docker logs -f <container>

# Exec
docker exec -it <container> /bin/bash

# Stop
docker stop <container>

# Start
docker start <container>

# Eliminar
docker rm <container>
```

---

## 🔍 Utilidades

### Networking
```bash
# Test de conectividad
curl -I https://example.com

# Test DNS
nslookup google.com

# Test puerto
nc -zv hostname port

# Ver puertos en uso
netstat -tulpn | grep LISTEN
# o
ss -tulpn
```

### Sistema
```bash
# Uso de CPU/Memoria
top
htop

# Espacio en disco
df -h

# Uso de directorio
du -sh <directory>

# Procesos
ps aux | grep <name>
```

### JSON/YAML
```bash
# Pretty print JSON
cat file.json | jq .

# Query JSON
cat file.json | jq '.key'

# YAML to JSON
yq -o=json file.yaml

# JSON to YAML
yq -P file.json
```

---

## 💾 Backup y Restore

### Kubernetes Backup
```bash
# Backup de recursos
kubectl get all --all-namespaces -o yaml > backup-all.yaml

# Backup de namespace específico
kubectl get all -n <namespace> -o yaml > backup-ns.yaml

# Backup de tipo específico
kubectl get deployments -A -o yaml > backup-deployments.yaml

# Restore
kubectl apply -f backup.yaml
```

### Terraform State
```bash
# Backup manual
terraform state pull > backup.tfstate

# Restore (cuidado!)
terraform state push backup.tfstate
```

---

## 🚨 Comandos de Emergencia

### Reinicio Rápido
```bash
# Restart deployment
kubectl rollout restart deployment <name> -n <namespace>

# Delete pod (se recrea automáticamente)
kubectl delete pod <name> -n <namespace>

# Drain node
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Cordon node
kubectl cordon <node>

# Uncordon node
kubectl uncordon <node>
```

### Debug Rápido
```bash
# Ver logs de pod con errores
kubectl logs <pod> -n <namespace> --previous

# Ver eventos recientes con errores
kubectl get events -A | grep -i error

# Test pod temporal
kubectl run test --image=busybox -it --rm -- /bin/sh

# Test de red
kubectl run nettest --image=nicolaka/netshoot -it --rm -- /bin/bash
```

---

## 📝 Aliases Útiles (agregar a ~/.bashrc)

```bash
# kubectl
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all -A'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kx='kubectl exec -it'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline'
```
