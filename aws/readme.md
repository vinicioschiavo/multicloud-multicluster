# Roteiro

O que iremos fazer?

## Parte 1
1. Criação de usuário do IAM e permissões
2. Criação da instância do RancherServer pela aws-cli
3. Configuração do Rancher.
4. Configuração do Cluster Kubernetes.
5. Deployment do cluster pela aws-cli.



## Parte 2
6. Configuração do Traefik
7. Configuração do Longhorn
8. Criação do certificado não válido
9. Configuração do ELB
10. Configuração do Route 53


Parabéns, com isso temos a primera parte da nossa infraestrutura. 
Estamos prontos para rodar nossa aplicação.


# Parte 1

## 1 - Criação de usuário do IAM e permissões e configuração da AWS-CLI

https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html


## 2 - Criação da instância do RancherServer pela aws-cli.

```sh 

# RANCHER SERVER

# --image-id              ami-006e00d6ac75d2ebb
# --instance-type         t3.medium
# --key-name              multicloud 
# --security-group-ids    sg-01814aeaca6fad6cf 
# --subnet-id             subnet-0c6963dffece83adf

$ aws ec2 run-instances --image-id ami-006e00d6ac75d2ebb --count 1 --instance-type t3.medium --key-name multicloud --security-group-ids sg-01814aeaca6fad6cf --subnet-id subnet-0c6963dffece83adf --user-data file://rancher.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rancherserver}]' 'ResourceType=volume,Tags=[{Key=Name,Value=rancherserver}]'

```


## 3 - Configuração do Rancher
Acessar o Rancher e configurar

https://44.200.139.173
## 4 - Configuração do Cluster Kubernetes.
Criar o cluster pelo Rancher e configurar.



## 5 - Deployment do cluster pela aws-cli

```sh
# --image-id ami-006e00d6ac75d2ebb
# --count 3 
# --instance-type t3.large 
# --key-name multicloud 
# --security-group-ids sg-01814aeaca6fad6cf 
# --subnet-id subnet-04df4be444e3859d1
# --user-data file://k8s.sh

$ aws ec2 run-instances --image-id ami-006e00d6ac75d2ebb --count 3 --instance-type t3.large --key-name multicloud --security-group-ids sg-01814aeaca6fad6cf --subnet-id subnet-04df4be444e3859d1 --user-data file://k8s.sh   --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 70 } } ]" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s}]'     
```

Instalar o kubectl 

https://kubernetes.io/docs/tasks/tools/


# Parte 2

## 6 - Configuração do Traefik

O Traefik é a aplicação que iremos usar como ingress. Ele irá ficar escutando pelas entradas de DNS que o cluster deve responder. Ele possui um dashboard de  monitoramento e com um resumo de todas as entradas que estão no cluster.
```sh
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
$ kubectl --namespace=kube-system get pods
```

Agora iremos configurar o DNS pelo qual o Traefik irá responder. No arquivo ui.yml, localizar a url, e fazer a alteração. Após a alteração feita, iremos rodar o comando abaixo para aplicar o deployment no cluster.
```sh
$ kubectl apply -f traefik.yaml
```


## 7 - Configuração do Longhorn
Pelo console do Rancher


## 8 - Criação do certificado
Criar certificado para nossos dominios:

 *.devops-verde.ml


```sh
> openssl req -new -x509 -keyout cert.pem -out cert.pem -days 365 -nodes
Country Name (2 letter code) [AU]:DE
State or Province Name (full name) [Some-State]:Germany
Locality Name (eg, city) []:nameOfYourCity
Organization Name (eg, company) [Internet Widgits Pty Ltd]:nameOfYourCompany
Organizational Unit Name (eg, section) []:nameOfYourDivision
Common Name (eg, YOUR name) []:*.devops-verde.ml
Email Address []:vinicioschiavo@gmail.com
```

arn:aws:acm:us-east-1:399679827371:certificate/3404868a-4219-4cdc-8455-d4c13101b5b6


## 9 - Configuração do ELB


```sh
# LOAD BALANCER

# !! ESPECIFICAR O SECURITY GROUPS DO LOAD BALANCER

# --subnets subnet-0c6963dffece83adf subnet-04df4be444e3859d1

$ aws elbv2 create-load-balancer --name multicloud --type application --subnets subnet-0c6963dffece83adf subnet-04df4be444e3859d1
#	 "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:399679827371:loadbalancer/app/multicloud/ce6de07d3a61469b"

# --vpc-id vpc-0519b1a5e1cdcfa33

$ aws elbv2 create-target-group --name multicloud --protocol HTTP --port 80 --vpc-id vpc-0519b1a5e1cdcfa33 --health-check-port 8080 --health-check-path /api/providers
#	 "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:399679827371:targetgroup/multicloud/f90b099bbc0ba262"
	
	
# REGISTRAR OS TARGETS  
$ aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:399679827371:targetgroup/multicloud/f90b099bbc0ba262 --targets Id=i-0044eafd25ca708bb Id=i-07592c81ed0134555 Id=i-01581f7f8bd7dc3ad


i-0044eafd25ca708bb
i-07592c81ed0134555
i-01581f7f8bd7dc3ad


# ARN DO Certificado - arn:aws:acm:us-east-1:399679827371:certificate/3404868a-4219-4cdc-8455-d4c13101b5b6
# HTTPS - CRIADO PRIMEIRO
$ aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:399679827371:loadbalancer/app/multicloud/ce6de07d3a61469b \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-1:399679827371:certificate/3404868a-4219-4cdc-8455-d4c13101b5b6   \
    --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:399679827371:targetgroup/multicloud/f90b099bbc0ba262
#  "ListenerArn": "arn:aws:elasticloadbalancing:us-east-1:399679827371:listener/app/multicloud/ce6de07d3a61469b/888b108c01f1ee05"


$ aws elbv2 describe-target-health --target-group-arn targetgroup-arn

# DESCRIBE NO LISTENER
$ aws elbv2 describe-listeners --listener-arns arn:aws:elasticloadbalancing:us-east-1:399679827371:listener/app/multicloud/ce6de07d3a61469b/888b108c01f1ee05


```


## 10 - Configuração do Route 53
Pelo console da AWS



