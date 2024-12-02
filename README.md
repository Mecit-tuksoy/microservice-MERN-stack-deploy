# NOT: README-image klasöründe README.md ve Ekran görüntüleri var!!!


# Terraform ile altyapinin oluşturulmasi:

Terraform main.tf dosyasi *infrastructure* dosyasindadir.

## Bu terraform yapisina göre:

 1- AWS'de "Node AutoScaling" yapabilecek bir EKS kurmak amaçlanmiştir.

 2- EKS default VPC'de oluşturulmuştur.

 3- Security Group'lari cluster içinde master node ve worker nodelarin birbiri ile iletişim kurabilecekleri şekilde yapilandirdim. Eks oluştuktan sonra manual olarak kubernetes service objesinde belirttiğim 30001, 30002 ve 9100 portlarini sonradan cnsol üzerinden ekkledim.

 4- EKS'nin oluşabilmesi ve benim yapim için gerekli olan izinleri verdiğim rolleri oluşturdum.

    eks_role'de: "AmazonEKSClusterPolicy", "CloudWatchFullAccess", "AutoScalingFullAccess", "AmazonEKSServicePolicy" kullandim.

    eks_node_group_role'de: "AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly", "ElasticLoadBalancingFullAccess",  "CloudWatchFullAccess", "AutoScalingFullAccess", kullandim. 

 5- Uygulama için Kubernetes "ingress" objesi kullanmadiğim için servis tipini Nodeport olarak ayarladiğim ve EKS'yi VPC dişindan erişilebilir şekilde yapilandirdim.

 6- Node gruplar için istenilen kapasite 1 ve maksimum 2 olarak ayarladim. Buna göre ölçeklenecek.

 7- Node'lara Ölçeklendirme yapabilmek için Data bloğu ile "aws_autoscaling_groups" bilgisini çekiyorum. Bu bilgiyi ölçeklendirme kurallarinda kullaniyorum. Node'larin 1'er 1'er artip azalmasi kuralini belirliyorum. CPU değeri %70'i geçtiğinde yeni makine ayağa kaldiriliyor. CPU değeri %30'dan aşağiya düştüğünde sirayla 1'er makine sonlandiriyor.


# Dockerfile yazilmasi

## Client klasörünün ana dizininde "Dockerfile" dosyasi oluşturuyoruz. içeriği ve açiklamasi şu şekilde;

````sh
# 1. Base image olarak resmi Node.js imajini kullandim.
FROM node:18

# 2. image içindeki çalişma dizinini
WORKDIR /usr/src/app

# 3. Önce image içine package.json ve package-lock.json dosyalarini kopyalayip bağimliliklarin önce yüklenmesini sağliyoruz.
COPY package*.json ./

# 4. Bağimliliklari yüklemek için
RUN npm install

# 5. Bağimliliklar yüklendikten sonra Uygulamanin diğer dosyalarini image içine kopyaliyoruz.
COPY . .

# 6. Uygulamanin çaliştiği portu belirtiyoruz
EXPOSE 3000

# 7. İmage çaliştirildiğinda Uygulamayi başlatacak komutu yaziyoruz.
CMD ["npm", "start"]
````

## Server klasörünün ana dizininde "Dockerfile" dosyasi oluşturuyoruz. içeriği ve açiklamasi şu şekilde;

````sh
# 1. Base image olarak resmi Node.js imajini kullandim.
FROM node:18

# 2. image içindeki çalişma dizinini
WORKDIR /usr/src/app

# 3. Önce image içine package.json ve package-lock.json dosyalarini kopyalayip bağimliliklarin önce yüklenmesini sağliyoruz.
COPY package*.json ./

# 4. Bağimliliklari yüklemek için
RUN npm install

# 5. Bağimliliklar yüklendikten sonra Uygulamanin diğer dosyalarini image içine kopyaliyoruz.
COPY . .

# 6. Uygulamanin çaliştiği portu belirtiyoruz
EXPOSE 5050

# 7. İmage çaliştirildiğinda Uygulamayi başlatacak komutu yaziyoruz.
CMD ["npm", "start"]
````


# jenkins için kullanilacak server ayarlamasi:

## Gerekli kurulumlar:

 1- Jenkins kurulumu. (scripts klasöründeki install_jenkins.sh dosyasini çaliştiriyoruz)

 2- jenkins pipelinedaki adimlar için gerekli kurulumlar:

     - Docker (scripts klasöründeki install_docker.sh dosyasini çaliştiriyoruz). Uygulama image'larinin Build edilmesi ve dockerhub'a push edilmesi için kullaniyoru.
  
     - Terraform (scripts klasöründeki install_terraform.sh dosyasini çaliştiriyoruz). EKS'nin oluşturulmasi için. 
      
     - kubectl (scripts klasöründeki install_kubect.sh dosyasini çaliştiriyoruz). jenkins'in EKS clusterda kubectl komutlarini çaliştirabilmesi için kuruyoruz.
      
     - Prometheus (scripts klasöründeki install_prometheus.sh dosyasini çaliştiriyoruz). Gerekli metrkleri toplamak için kuruyoruz.
      
     - Grafana (scripts klasöründeki install_grafana.sh dosyasini çaliştiriyoruz). Prometheus metriklerini görselleştirmek için kuruyoruz.
      
     - Node_exporter (scripts klasöründeki install_node_exporter.sh dosyasini çaliştiriyoruz). EKS'nin metriklerini alabilmek için kuruyoruz.
      
     - Cypress (scripts klasöründeki install_node_cypress.sh dosyasini çaliştiriyoruz). Uygulama çalişirken test etmek için kullaniyoruz.
  
     - Trivy (scripts klasöründeki install_trivy.sh dosyasini çaliştiriyoruz). Githubdan klonlanan dosya sistemindeki  ve konteyner imajlarindaki güvenlik açiklarini (vulnerabilities) tespit etmek için kullanilniyoruz.


### *bu kurulum aşamalari README-image klasöründeki ekran görselleri ile README.md dosyasinda gösterilmiştir.*

# Kubernetes dosyalari:

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *backend-deployment-service.yaml*, *frontend-deployment-service.yaml* ve *mongodb-deployment-service.yaml* ile; 
  Podlari oluşturacak ve sayisini ayarlayacak deployment objesinde image ismi, port numarasi, gerekli değişkenler, gerekli metrikler ve kurallar belirlendi. Ayrica service objesi ile de podlar takip edilip onlara bir servis oluşturulup Nodeport tipi ilede belirlenen porta yönlendirme yapilmiştir.

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *HPA-backend-deployment.yaml* ve *HPA-frontend-deployment.yaml* ile; 
  frontend-deployment ve backend-deployment takip edilerek cpu kullanimi %90'i geçtiğinde minimum 1 maksimum 10 olacak şekilde pod ölçeklendirmesi yapmaktadir.

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *mongodb-secret.yaml* ile; 
  Deployment objsinde kullanilmak üzere mongodb için gerekli olacak bilgiler base64 formatinda oluşturuluyor.

Ana dizinde bulunan *k8s* klasörünün içinde bulunan, *pv-pvc.yaml* ile;  
  Mongodb'nin verilerinin tutulacaği volüm temin ediliyor.


  # Jenkinsfile yapilandirmasi:

Jenkinsfile dosyasi ana dizindedir.

##Bu Jenkinsfile ile:

   1- Pipeline içinde kullanilan değişkenler tanimlanmiştir.

   2- 'Clean Workspace' bu adiminda Jenkinsin çalişma alanini temizleniyor.

   3- 'Clone Repository' Git reposu klonlaniyor.
   
   4- 'Run Security Scans' bu adimda indirilen dosyalarin güvenlik taramasi yapiliyor.

   5- 'Check Security Scan Results' güvenlik taramasi sonrasinda "CRITICAL" "HIGH" sonuçlarina göre pipeline devam edip etmeyeceği değerlendiriliyor. Bu aşamada pipeline sonlanmamasi için yorum satiri yaptim.

   6- 'Apply Terraform (Backend Resources)' EKS cluster oluşturan terraform dosyasi çaliştirilmadan önce 'tfstate' dosyamizin tutulmasi için AWS S3'de bir bucket oluşturuluyor ve dosyalarin şifreli tutulmasi ve versiyonlu tutulmasi sağlaniyor. Ek olrak bu adimda dynamodb table oluşturularak lock kaydi tutuluyorki çakişmalar yaşanmasin. Eğer önceden oluşturulduysa bu adim atlanacak şekilde yazildi.

   7- 'Apply Terraform (EKS Cluster)' EKS'yi oluşturacak terraform dosyasi ile EKS kontrol ediliyor eğer önceden oluşturulduysa bu adim atlaniyor oluşturulmadiysa EKS oluşturuluyor.

   8-  'Deploy Metrics Server and Node Exporter' Kubernetes cluster'ina erişim sağlamak için kubeconfig dosyasini günceller. Kubernetes cluster'indaki node'lar ve pod'lar hakkinda CPU, bellek gibi temel metrikleri toplamak ve Horizontal Pod Autoscaler (HPA) için Metrics Server yüklenir. Kubernetes node'lari hakkinda sistem metriklerini toplama için Node Exporter kurulur

   9- 'Public IP' EKS nodelarinin ipisi alinir "public_ips.txt" dosyasina yazdirilir.

   10- 'Update Prometheus Configuration' bu aşamada "public_ips.txt" dosyasindaki ip "/etc/prometheus/prometheus.yml" dosyasina uygun şekilde eklenir ve prometheus yeniden başlatilir.

   11- 'Update Configuration Files' bu aşamada "public_ips.txt" dosyasindaki ip uygulamanin değiştirilmesi gereken yerlerindeki "localhost" ile değiştirilir.

   12- 'Tag and Build  Application' hazir hale gelen uygulama dosyalariyla docker image i oluşturulur ve çiktilari "image-build-logs.txt" dosyasina yazdirlir.

   13- 'Run Security Scans on Docker Images' trivy ile oluşan imagelarda güvenlik taramasi yapilir çiktilari 'test-image.txt' dosyasina yazdirilir. "--severity HIGH,CRITICAL" durumuna göre pipeline sonlandirilmasi yorum satiri yaptim.

   14- 'Push Docker Images' oluşan docker image lari dockerhub'a push edilir.

   15- 'EKS Deploy' image hazir olduktan sonra kubernetes dosyalari çaliştirilir ve EKS üzerine deploy edilmiş olur.

   16- 'Install Node.js and npm' Jenkins ortaminda node.js ve npm yüklü değilse yükleme yapilir.

   17- 'Install Dependencies' uygulamanin test edilebilmesi için gerekli bağimliliklar yüklenir.

   18- 'Run Cypress Tests' Uygulama test edilir. sonuçlari "app-test-results.txt" dosyasina yazdirilir. Bu aşamada test sonucu kodlarda bulunan hata nedeni ile pipeline durmamasi için devam edecek şekilde yazildi.

   19- 'Test Application Deployment' uygulamanin GET  ve POST isteklerine cevabi test edilir ve sonuçlari POST-GET-test.txt dosyasina yazdirilir.

   20- post adiminda pipeline içinde yapilan test sonuçlari bir email olarak kayitli mail hesabina gönderilir.


# Jenkin konsolunda yapilan ayarlamalar ekran görüntüleri ile *README-image* klasörünün içinde *README.md* dosyasinda bulunmaktadir. 

# Sonur çözümü için kullanilan bazi komutlar;

Jenkins serverda kubectl yüklü olduğundan cluster'i yönetmek için terminalde şu komutu girebiliriz:

````sh
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster
````

````sh
#kubernetes için:
kubectl apply -f .
kubectl delete -f .
kubectl version --client        
kubectl get node
kubectl get pod
kubectl get svc
kubectl exec -it <pod-ismi> -- sh  
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
git push origin main             #>>> main branch'e yapilan merge remote repository'ye gönderir.
git merge main
git push origin feature/devops



#docker için;
docker ps -a
docker-compose -up
docker-compose down
docker build -t <image ismi> <dockerfile konumu>
docker login
docker push <image ismi>
docker run -it --name <container-ismi> --p 3000:3000 <image ismi>
docker logs <container ismi>

#diğer
netstat -tuln
curl -X POST http://${workerNodeIP}:30002/record   -H "Content-Type: application/json" -d '{"name": "mecit", "position": "DevOps", "level": "Middle"}'
sudo su - jenkins
sudo systemctl status prometheus
sudo nano /etc/prometheus/prometheus.yml
which grafana-server
systemctl list-units --type=service | grep grafana
systemctl status grafana-server.service
sudo systemctl restart grafana-server.service
````

