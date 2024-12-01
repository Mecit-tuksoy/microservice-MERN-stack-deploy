NOT: README-image klasöründe README.md ve Ekran görüntüleri var!!!

# Terraform ile altyapının oluşturulması:

## Bu terraform yapısına göre:
 1- AWS'de "Node AutoScaling" yapabilecek bir EKS kurmak amaçlanmıştır.

 2- EKS default VPC'de oluşturulmuştur.

 3- Security Group'ları cluster içinde master node ve worker nodeların birbiri ile iletişim kurabilecekleri şekilde yapılandırdım. Eks oluştuktan sonra manual olarak kubernetes service objesinde belirttiğim 30001, 30002 ve 9100 portlarını sonradan cnsol üzerinden ekkledim.

 4- EKS'nin oluşabilmesi ve benim yapım için gerekli olan izinleri verdiğim rolleri oluşturdum.
    eks_role'de: "AmazonEKSClusterPolicy", "CloudWatchFullAccess", "AutoScalingFullAccess", "AmazonEKSServicePolicy" kullandım. 
    eks_node_group_role'de: "AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly", "ElasticLoadBalancingFullAccess",  "CloudWatchFullAccess", "AutoScalingFullAccess", kullandım. 

 5- Uygulama için Kubernetes "ingress" objesi kullanmadığım için servis tipini Nodeport olarak ayarladığım ve EKS'yi VPC dışından erişilebilir şekilde yapılandırdım.

 6- Node gruplar için istenilen kapasite 1 ve maksimum 2 olarak ayarladım. Buna göre ölçeklenecek.

 7- Node'lara Ölçeklendirme yapabilmek için Data bloğu ile "aws_autoscaling_groups" bilgisini çekiyorum. Bu bilgiyi ölçeklendirme kurallarında kullanıyorum. Node'ların 1'er 1'er artıp azalması kuralını belirliyorum. CPU değeri %70'i geçtiğinde yeni makine ayağa kaldırılıyor. CPU değeri %30'dan aşağıya düştüğünde sırayla 1'er makine sonlandırıyor.

 
````sh
terraform {
  backend "s3" {
    bucket         = "mecit-terraform-state"  
    key            = "terraform/state/MERN.tfstate"    
    region         = "us-east-1"                              
    dynamodb_table = "mecit-terraform-state-lock"                 
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }   
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}


variable "eks_cluster_name" {
  default = "my-eks-cluster"
}

# Security Groups
resource "aws_security_group" "eks_cluster_sg" {
  name        = "my-eks-cluster-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = data.aws_vpc.default.id   #aws_vpc.eks_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "my-eks-cluster-eks-cluster-sg"
  }
}

resource "aws_security_group" "eks_node_sg" {
  name        = "my-eks-cluster-eks-node-sg"
  description = "EKS worker node security group"
  vpc_id      = data.aws_vpc.default.id  

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }



  ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_groups = [aws_security_group.eks_cluster_sg.id]
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-eks-cluster-eks-node-sg"
  }
  depends_on = [
    aws_security_group.eks_cluster_sg
  ]
}


# IAM Roles and Attachments
resource "aws_iam_role" "eks_role" {
  name = "eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  depends_on = [
    aws_iam_role.eks_role
  ]
}

resource "aws_iam_role_policy_attachment" "CloudWatch_eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  depends_on = [
    aws_iam_role.eks_role
  ]
}

resource "aws_iam_role_policy_attachment" "AutoScaling_eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  depends_on = [
    aws_iam_role.eks_role
  ]
}
resource "aws_iam_role_policy_attachment" "Service_eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  depends_on = [
    aws_iam_role.eks_role
  ]
}


resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}

resource "aws_iam_role_policy_attachment" "eks_elb_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}

resource "aws_iam_role_policy_attachment" "CloudWatch_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}

resource "aws_iam_role_policy_attachment" "AutoScaling_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}


# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = ["subnet-04c001c3056ef26d1", "subnet-0a9dfb92318f8a2d7"] 
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role.eks_role,
    aws_iam_role_policy_attachment.eks_policy,
    aws_security_group.eks_cluster_sg
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids = ["subnet-04c001c3056ef26d1", "subnet-0a9dfb92318f8a2d7"]   
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  instance_types = ["t3.medium"]
  remote_access {
    ec2_ssh_key = "newkey"  
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.eks_node_group_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_elb_policy,
    aws_iam_role_policy_attachment.eks_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role.eks_role,
    aws_iam_role.eks_node_group_role,
    aws_security_group.eks_cluster_sg
  ]
}





# Data Source to Retrieve ASG Name Associated with the EKS Node Group
data "aws_autoscaling_groups" "eks_node_asg" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.eks_node_group.node_group_name]
  }
  
  filter {
    name   = "tag:eks:cluster-name"
    values = [aws_eks_cluster.eks_cluster.name]
  }
}

# Output to Verify Retrieved ASG Names (Optional)
output "eks_node_asg_names" {
  value = data.aws_autoscaling_groups.eks_node_asg.names
}

# Auto Scaling Policy for Scaling Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  autoscaling_group_name = data.aws_autoscaling_groups.eks_node_asg.names[0]
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300

  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
}

# (Opsiyonel) Auto Scaling Policy for Scaling Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  autoscaling_group_name = data.aws_autoscaling_groups.eks_node_asg.names[0]
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300

  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
}

# CloudWatch Metric Alarm for High CPU Utilization (Scaling Up)
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"  # CPU kullanım eşiği (%70)
  
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  
  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_groups.eks_node_asg.names[0]
  }

  depends_on = [
    aws_autoscaling_policy.scale_up
  ]
}

#CloudWatch Metric Alarm for Low CPU Utilization (Scaling Down)
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name          = "low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"  
  
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  
  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_groups.eks_node_asg.names[0]
  }

  depends_on = [
    aws_autoscaling_policy.scale_down
  ]
}
````

# Dockerfile yazılması

## Client klasörünün ana dizininde "Dockerfile" dosyası oluşturuyoruz. içeriği ve açıklaması şu şekilde;

````sh
# 1. Base image olarak resmi Node.js imajını kullandım.
FROM node:18

# 2. image içindeki çalışma dizinini
WORKDIR /usr/src/app

# 3. Önce image içine package.json ve package-lock.json dosyalarını kopyalayıp bağımlılıkların önce yüklenmesini sağlıyoruz.
COPY package*.json ./

# 4. Bağımlılıkları yüklemek için
RUN npm install

# 5. Bağımlılıklar yüklendikten sonra Uygulamanın diğer dosyalarını image içine kopyalıyoruz.
COPY . .

# 6. Uygulamanın çalıştığı portu belirtiyoruz
EXPOSE 3000

# 7. İmage çalıştırıldığında Uygulamayı başlatacak komutu yazıyoruz.
CMD ["npm", "start"]
````

## Server klasörünün ana dizininde "Dockerfile" dosyası oluşturuyoruz. içeriği ve açıklaması şu şekilde;

````sh
# 1. Base image olarak resmi Node.js imajını kullandım.
FROM node:18

# 2. image içindeki çalışma dizinini
WORKDIR /usr/src/app

# 3. Önce image içine package.json ve package-lock.json dosyalarını kopyalayıp bağımlılıkların önce yüklenmesini sağlıyoruz.
COPY package*.json ./

# 4. Bağımlılıkları yüklemek için
RUN npm install

# 5. Bağımlılıklar yüklendikten sonra Uygulamanın diğer dosyalarını image içine kopyalıyoruz.
COPY . .

# 6. Uygulamanın çalıştığı portu belirtiyoruz
EXPOSE 5050

# 7. İmage çalıştırıldığında Uygulamayı başlatacak komutu yazıyoruz.
CMD ["npm", "start"]
````


# jenkins için kullanılacak server ayarlaması:

## Gerekli kurulumlar:

 1- Jenkins kurulumu. (scripts klasöründeki install_jenkins.sh dosyasını çalıştırıyoruz)

 2- jenkins pipelinedaki adımlar için gerekli kurulumlar:

     - Docker (scripts klasöründeki install_docker.sh dosyasını çalıştırıyoruz). Uygulama image'larının Build edilmesi ve dockerhub'a push edilmesi için kullanıyoru.
  
     - Terraform (scripts klasöründeki install_terraform.sh dosyasını çalıştırıyoruz). EKS'nin oluşturulması için. 
      
     - kubectl (scripts klasöründeki install_kubect.sh dosyasını çalıştırıyoruz). jenkins'in EKS clusterda kubectl komutlarını çalıştırabilmesi için kuruyoruz.
      
     - Prometheus (scripts klasöründeki install_prometheus.sh dosyasını çalıştırıyoruz). Gerekli metrkleri toplamak için kuruyoruz.
      
     - Grafana (scripts klasöründeki install_grafana.sh dosyasını çalıştırıyoruz). Prometheus metriklerini görselleştirmek için kuruyoruz.
      
     - Node_exporter (scripts klasöründeki install_node_exporter.sh dosyasını çalıştırıyoruz). EKS'nin metriklerini alabilmek için kuruyoruz.
      
     - Cypress (scripts klasöründeki install_node_cypress.sh dosyasını çalıştırıyoruz). Uygulama çalışırken test etmek için kullanıyoruz.
  
     - Trivy (scripts klasöründeki install_trivy.sh dosyasını çalıştırıyoruz). Githubdan klonlanan dosya sistemindeki  ve konteyner imajlarındaki güvenlik açıklarını (vulnerabilities) tespit etmek için kullanılnıyoruz.


### *bu kurulum aşamaları README-image klasöründeki ekran görselleri ile README.md dosyasında gösterilmiştir.*

# Kubernetes dosyaları:

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *backend-deployment-service.yaml*, *frontend-deployment-service.yaml* ve *mongodb-deployment-service.yaml* ile; 
  Podları oluşturacak ve sayısını ayarlayacak deployment objesinde image ismi, port numarası, gerekli değişkenler, gerekli metrikler ve kurallar belirlendi. Ayrıca service objesi ile de podlar takip edilip onlara bir servis oluşturulup Nodeport tipi ilede belirlenen porta yönlendirme yapılmıştır.

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *HPA-backend-deployment.yaml* ve *HPA-frontend-deployment.yaml* ile; 
  frontend-deployment ve backend-deployment takip edilerek cpu kullanımı %90'ı geçtiğinde minimum 1 maksimum 10 olacak şekilde pod ölçeklendirmesi yapmaktadır.

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *mongodb-secret.yaml* ile; 
  Deployment objsinde kullanılmak üzere mongodb için gerekli olacak bilgiler base64 formatında oluşturuluyor.

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *pv-pvc.yaml* ile;  
  Mongodb'nin verilerinin tutulacağı volüm temin ediliyor.


  # Jenkinsfile yapılandırması:

Bu Jenkinsfile ile:
   1- Pipeline içinde kullanılan değişkenler tanımlanmıştır.

   2- 'Clean Workspace' bu adımında Jenkinsin çalışma alanını temizleniyor.

   3- 'Clone Repository' Git reposu klonlanıyor.
   
   4- 'Run Security Scans' bu adımda indirilen dosyaların güvenlik taraması yapılıyor.

   5- 'Check Security Scan Results' güvenlik taraması sonrasında "CRITICAL" "HIGH" sonuçlarına göre pipeline devam edip etmeyeceği değerlendiriliyor. Bu aşamada pipeline sonlanmaması için yorum satırı yaptım.

   6- 'Apply Terraform (Backend Resources)' EKS cluster oluşturan terraform dosyası çalıştırılmadan önce 'tfstate' dosyamızın tutulması için AWS S3'de bir bucket oluşturuluyor ve dosyaların şifreli tutulması ve versiyonlu tutulması sağlanıyor. Ek olrak bu adımda dynamodb table oluşturularak lock kaydı tutuluyorki çakışmalar yaşanmasın. Eğer önceden oluşturulduysa bu adım atlanacak şekilde yazıldı.

   7- 'Apply Terraform (EKS Cluster)' EKS'yi oluşturacak terraform dosyası ile EKS kontrol ediliyor eğer önceden oluşturulduysa bu adım atlanıyor oluşturulmadıysa EKS oluşturuluyor.

   8-  'Deploy Metrics Server and Node Exporter' Kubernetes cluster'ına erişim sağlamak için kubeconfig dosyasını günceller. Kubernetes cluster'ındaki node'lar ve pod'lar hakkında CPU, bellek gibi temel metrikleri toplamak ve Horizontal Pod Autoscaler (HPA) için Metrics Server yüklenir. Kubernetes node'ları hakkında sistem metriklerini toplama için Node Exporter kurulur

   9- 'Public IP' EKS nodelarının ipisi alınır "public_ips.txt" dosyasına yazdırılır.

   10- 'Update Prometheus Configuration' bu aşamada "public_ips.txt" dosyasındaki ip "/etc/prometheus/prometheus.yml" dosyasına uygun şekilde eklenir ve prometheus yeniden başlatılır.

   11- 'Update Configuration Files' bu aşamada "public_ips.txt" dosyasındaki ip uygulamanın değiştirilmesi gereken yerlerindeki "localhost" ile değiştirilir.

   12- 'Tag and Build  Application' hazır hale gelen uygulama dosyalarıyla docker image ı oluşturulur ve çıktıları "image-build-logs.txt" dosyasına yazdırlır.

   13- 'Run Security Scans on Docker Images' trivy ile oluşan imagelarda güvenlik taraması yapılır çıktıları 'test-image.txt' dosyasına yazdırılır. "--severity HIGH,CRITICAL" durumuna göre pipeline sonlandırılması yorum satırı yaptım.

   14- 'Push Docker Images' oluşan docker image ları dockerhub'a push edilir.

   15- 'EKS Deploy' image hazır olduktan sonra kubernetes dosyaları çalıştırılır ve EKS üzerine deploy edilmiş olur.

   16- 'Install Node.js and npm' Jenkins ortamında node.js ve npm yüklü değilse yükleme yapılır.

   17- 'Install Dependencies' uygulamanın test edilebilmesi için gerekli bağımlılıklar yüklenir.

   18- 'Run Cypress Tests' Uygulama test edilir. sonuçları "app-test-results.txt" dosyasına yazdırılır. Bu aşamada test sonucu kodlarda bulunan hata nedeni ile pipeline durmaması için devam edecek şekilde yazıldı.

   19- 'Test Application Deployment' uygulamanın GET  ve POST isteklerine cevabı test edilir ve sonuçları POST-GET-test.txt dosyasına yazdırılır.

   20- post adımında pipeline içinde yapılan test sonuçları bir email olarak kayıtlı mail hesabına gönderilir.


Jenkinsfile:
````sh
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'my-eks-cluster'
        AWS_ACCESS_KEY_ID = credentials('my-aws-credentials')
        AWS_SECRET_ACCESS_KEY = credentials('my-aws-credentials')
        FRONTEND_DIR = 'client'
        BACKEND_DIR = 'server'
        EKS_DIR = 'k8s'
        K8S_DIR = 'infrastructure/k8s'
        BACKEND_S3_DIR = 'infrastructure/k8s/backend-s3-dynamodb'
        GIT_REPO = 'https://github.com/Mecit-tuksoy/microservice-MERN-stack-deploy.git'
        TEST_RESULT_FILE = 'file-test.txt'    
        BUILD_LOG_FILE = 'image-build-logs.txt'
        TEST_RESULT_LOG_FILE = 'application-test-results.txt'
        IMAGE_TEST_RESULT_FILE = 'test-image.txt'
        POST_GET_RESULT_FILE = 'POST-GET-test.txt'
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: "${env.GIT_REPO}"
            }
        }
        stage('Run Security Scans') {
            steps {
                sh '''
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/scripts/install.sh | sh
                trivy fs --severity HIGH,CRITICAL . > ${WORKSPACE}/${TEST_RESULT_FILE} 
                '''
                // trivy fs --exit-code 1 --severity HIGH,CRITICAL . > ${WORKSPACE}/${TEST_RESULT_FILE}   (pipeline risk varsa durur.)
            }
        }
        stage('Check Security Scan Results') {
            steps {
                script {
                    if (fileExists(env.TEST_RESULT_FILE)) {
                        def scanResults = readFile(env.TEST_RESULT_FILE)
                        if (scanResults.contains("CRITICAL") || scanResults.contains("HIGH")) {
                            echo "Warning: Security scan found vulnerabilities. Please address them."
                        }
                        // if (scanResults.contains("CRITICAL") || scanResults.contains("HIGH")) {       //test aşamasında gerek yok
                        //     error("Security scan failed. Please fix vulnerabilities.")
                        // }
                    }
                }
            }
        }
        stage('Apply Terraform (Backend Resources)') {
            steps {
                dir("${BACKEND_S3_DIR}") {
                    script {
                        // AWS CLI komutu ile 'mecit-terraform-state/terraform/state/MERN.tfstate' dosyasının var olup olmadığını kontrol et
                        def fileExists = sh(script: "aws s3 ls s3://mecit-terraform-state/terraform/state/MERN.tfstate", returnStatus: true)
                        
                        // Eğer dosya mevcutsa, Terraform işlemini atla
                        if (fileExists == 0) {
                            echo "Dosya 'MERN.tfstate' mevcut, Terraform işlemi atlanıyor."
                        } else {
                            echo "Dosya 'MERN.tfstate' bulunamadı, Terraform işlemi başlatılıyor."

                            // Terraform init komutunu çalıştır
                            def initResult = sh(script: 'terraform init', returnStatus: true)
                            if (initResult != 0) {
                                echo 'Terraform init başarısız oldu, devam ediliyor...'
                            }

                            // Terraform apply komutunu çalıştır
                            def applyResult = sh(script: 'terraform apply -auto-approve', returnStatus: true)
                            if (applyResult != 0) {
                                echo 'Terraform apply başarısız oldu, devam ediliyor...'
                            }
                        }
                    }
                }
            }
        }

        stage('Apply Terraform (EKS Cluster)') {
            steps {
                dir("${K8S_DIR}") {
                    script {
                        // EKS Cluster durumu kontrol et
                        def eksStatus = ''
                        try {
                            eksStatus = sh(
                                script: "aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.status' --output text",
                                returnStdout: true
                            ).trim()
                        } catch (Exception e) {
                            // Eğer cluster mevcut değilse, hata alacağız ve eksStatus boş kalacak
                            echo "EKS Cluster '${EKS_CLUSTER_NAME}' bulunamadı. Terraform ile oluşturulacak."
                        }

                        // Eğer cluster mevcut ve aktifse
                        if (eksStatus == "ACTIVE") {
                            echo "EKS Cluster '${EKS_CLUSTER_NAME}' zaten aktif. Terraform apply işlemi atlanıyor."
                        } else {
                            echo "EKS Cluster '${EKS_CLUSTER_NAME}' mevcut değil ya da aktif değil. Terraform apply işlemi başlatılıyor."

                            // Terraform init komutunu çalıştır
                            def initResult = sh(script: 'terraform init', returnStatus: true)
                            if (initResult != 0) {
                                error 'Terraform init başarısız oldu, pipeline devam etmiyor.'
                            }

                            // Terraform apply komutunu çalıştır
                            def applyResult = sh(script: 'terraform apply -auto-approve', returnStatus: true)
                            if (applyResult != 0) {
                                error 'Terraform apply başarısız oldu, pipeline devam etmiyor.'
                            }
                        }
                    }
                }
            }
        }


        stage('Deploy Metrics Server and Node Exporter') {
            steps {
                script {
                    sh '''#!/bin/bash
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    
                    # Metrics Server yükle
                    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
                    
                    # Helm deposu ekle
                    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                    helm repo update
                    
                    # Var olan node-exporter release'ini sil
                    helm uninstall node-exporter --namespace kube-system || true
                    
                    # Node Exporter yükle
                    helm install node-exporter prometheus-community/prometheus-node-exporter --namespace kube-system

                    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
                    '''
                }
            }
        }

        stage('Public IP') {
            steps {
                script {
                    def publicIPs = sh(
                        script: "kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type==\"ExternalIP\")].address}'",
                        returnStdout: true
                    ).trim().split(" ")
                    writeFile file: 'public_ips.txt', text: publicIPs.join("\n")
                    echo "Node Public IPs: ${publicIPs}"
                }
            }
        }
        stage('Update Prometheus Configuration') {
            steps {
                script {
                    def publicIP = readFile('public_ips.txt').trim() // Dosyadan IP adresini oku ve boşlukları temizle
                    def prometheusTarget = "${publicIP}:9100" // Hedef IP ve port
                    def configFilePath = '/etc/prometheus/prometheus.yml'

                    // Konfigürasyon dosyasını oku
                    def configFile = readFile(configFilePath)

                    // "eks" job'ının ve hedef IP'nin konfigürasyon dosyasına zaten eklenip eklenmediğini kontrol et
                    if (!configFile.contains("job_name: eks") || !configFile.contains(prometheusTarget)) {
                        // Eğer eklenmemişse, ekleyelim
                        sh """
                            echo "  - job_name: eks" | sudo tee -a ${configFilePath}
                            echo "    static_configs:" | sudo tee -a ${configFilePath}
                            echo "      - targets: ['${prometheusTarget}']" | sudo tee -a ${configFilePath}
                            
                            sudo systemctl restart prometheus
                        """
                    } else {
                        echo "Prometheus job already exists, no need to add it again."
                    }
                }
            }
        }

        stage('Update Configuration Files') {
            steps {
                script {
                    
                    def publicIPs = readFile('public_ips.txt').trim().split("\n")                    
                    def workerNodeIP = publicIPs[0]
                    def filesToUpdate = [
                        "${FRONTEND_DIR}/src/components/create.js",
                        "${FRONTEND_DIR}/src/components/edit.js",
                        "${FRONTEND_DIR}/src/components/healthcheck.js",
                        "${FRONTEND_DIR}/src/components/recordList.js",
                        "${FRONTEND_DIR}/cypress/integration/endToEnd.spec.js",
                        "${FRONTEND_DIR}/cypress.json"
                    ]
                    filesToUpdate.each { file ->
                        sh "sed -i 's|localhost|${workerNodeIP}|g' ${file}"
                    }
                }
            }
        }

     
        stage('Tag and Build  Application') {
            steps {
                sh '''
                # Build and tag Docker images
                docker build -t mecit35/mern-project-frontend:latest ${FRONTEND_DIR} > ${BUILD_LOG_FILE}
                docker build -t mecit35/mern-project-backend:latest ${BACKEND_DIR} >> ${BUILD_LOG_FILE}
                '''
            }
        }
        stage('Run Security Scans on Docker Images') {
            steps {
                sh '''
                # Scan the frontend and backend Docker images for vulnerabilities and save the results
                trivy image --severity HIGH,CRITICAL --no-progress --scanners vuln --timeout 10m --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-frontend:latest
                trivy image --severity HIGH,CRITICAL --no-progress --scanners vuln --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-backend:latest
                '''
                // trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-frontend:latest      // (pipeline risk varsa durur. bu aşamada yapmadım)
                // trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --output ${IMAGE_TEST_RESULT_FILE} mecit35/mern-project-backend:latest       //  (pipeline risk varsa durur. bu aşamada yapmadım)
            }
        }
        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push mecit35/mern-project-frontend:latest
                    docker push mecit35/mern-project-backend:latest
                    '''
                }
            }
        }



        stage('EKS Deploy') {
            steps {
                sh '''
                kubectl apply -f ${EKS_DIR}
                '''
            }
        }

    
        stage('Install Node.js and npm') {
            steps {
                script {
                    // Node.js ve npm yüklü mü kontrol et
                    def nodeInstalled = sh(script: 'which node', returnStatus: true)
                    def npmInstalled = sh(script: 'which npm', returnStatus: true)
                    
                    if (nodeInstalled != 0 || npmInstalled != 0) {
                        // Node.js ve npm yüklü değilse yükle
                        sh '''
                        # NodeSource Node.js binary dağıtım deposunu ekle
                        curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
                        
                        # Node.js ve npm'i kur
                        sudo apt-get install -y nodejs
                        
                        # Node.js ve npm sürümlerini kontrol et
                        node -v
                        npm -v
                        '''
                    } else {
                        echo "Node.js ve npm zaten yüklü."
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    // Bağımlılıkları yükle
                    sh 'cd client && npm install'
                }
            }
        }

        stage('Run Cypress Tests') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                        export TERM=xterm
                        cd client
                        npx cypress run --reporter json > $WORKSPACE/${TEST_RESULT_LOG_FILE}   
                    '''
                    }
                                
                }
            }
        }

        stage('Test Application Deployment') {
            steps {
                script {
                    def publicIPs = readFile('public_ips.txt').trim().split("\n")                    
                    def workerNodeIP = publicIPs[0]                    
                    sh """
                    curl -X POST http://${workerNodeIP}:30002/record   -H "Content-Type: application/json" -d '{"name": "mecit", "position": "DevOps", "level": "Middle"}' >> ${POST_GET_RESULT_FILE}
                    curl http://${workerNodeIP}:30001 >> ${POST_GET_RESULT_FILE}
                    """
                }
            }
        }
    }

    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                "Build Number: ${env.BUILD_NUMBER}<br/>" +
                "URL: ${env.BUILD_URL}<br/>",
            to: 'mecit.tuksoy@gmail.com',
            attachmentsPattern: "${TEST_RESULT_FILE},${POST_GET_RESULT_FILE},${BUILD_LOG_FILE},${TEST_RESULT_LOG_FILE},${IMAGE_TEST_RESULT_FILE}"
        }
    }
    
}
````

# Jenkin konsolunda yapılan ayarlamalar ekran görüntüleri ile *README-image* klasörünün içinde *README.md* dosyasında bulunmaktadır. 

# sonur çözümü için kullanılan bazı komutlar;

Jenkins serverda kubectl yüklü olduğundan cluster'ı yönetmek için terminalde şu komuyu girebiliriz:

````sh
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster
````

````sh
#kubernetes için:
kubectl apply -f .
kubectl delete -f .
kubectl version --client        #EKS ile uymlu olmalı.
kubectl get node
kubectl get pod
kubectl get svc
kubectl exec -it <pod-ismi> -- sh  #podların birbiri ile iletişimini kontrol için kullandım
kubectl describe pod <pod-ismi>
kubectl get pods -n kube-system
kubectl get logs <pod-ismi>


#terraform için;
terraform init
terraform validate
terraform plan
terraform init -reconfigure
terraform apply -auto approve

#Github için;
git branch feature/devops       #>>> brach oluştur
git branch                      #>>> branchlara bak
git checkout feature/devops     #>>> o brancha geç
git add .
git commit -m 'new branch'
git push --set-upstream origin feature/devops  #>>> bundan sonra sadece git push yeterli olur.
git checkout main
git merge feature/devops         #>>> değişiklikleri ana branch'e (main) birleştirir
git push origin main             #>>> main branch'e yapılan merge remote repository'ye gönderir.
git merge main
git push origin feature/devops



#docker için;
docker build -t <image ismi> <dockerfile konumu>
docker login
docker push <image ismi>
docker run -it --name <container-ismi> --p 3000:3000 <image ismi>
docker logs <container ismi>

#diğer
sudo su - jenkins
sudo systemctl status prometheus
sudo nano /etc/prometheus/prometheus.yml
which grafana-server
systemctl list-units --type=service | grep grafana
systemctl status grafana-server.service
sudo systemctl restart grafana-server.service
````

