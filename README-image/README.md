# jenkins server için gerekli yüklemeler:

## jenkins kurulumu:

Scripts/install_jenkins.sh

openjdk-17-jdk yüklü değilse onuda yükleyecek şekilde yapılandırıldı

![alt text](<jenkins yükleme.png>)

![alt text](<jenkins yükleme tamam.png>)

## nodejs ve cypress kurulumu:

Scripts/install_node_cypress.sh

![alt text](<nodejs ve cypress yükleme.png>)
![alt text](<node ve cypress tamam.png>)


## terraform kurulumu:

Scripts/install_terraform.sh

![alt text](<terraform yükleme.png>)

## docker kurulumu:
Scripts/install_docker.sh

Burada jenkins'ide docker grubuna ekliyorum. Daha sonra kullanmak için

![alt text](<docker yükleme.png>)
![alt text](<docker yükleme tamam.png>)

## trivy kurulumu:
Güvenlik testleri için.

Scripts/install_trivy.sh

![alt text](<trivy yükleme.png>)
![alt text](<trivy yükleme tamam.png>)

## kubectl kurulumu:

kubernetes ile terminalde işlem yapabilmek için.

Scripts/install_kubectl.sh

![alt text](<kubectl yükleme.png>)
![alt text](<kubectl yükleme tamam.png>)

## grafana kurulumu:

metrikleri görselleştirmek için

![alt text](<grafana yükleme.png>)
![alt text](<grafana yükleme tamam.png>)

## prometheus kurulumu:
metrikleri alabilmek için

Scripts/install_prometheus.sh

![alt text](<prometheus yükleme.png>)
![alt text](<prometheus yükleme tamam.png>)

Jenkinse "Prometheus metrics" eklentisini ekleyip yeniden başlatıyoruz.
````sh
sudo systemctl restart jenkins
````

jenkins'in metriklerini toplayabilmesi için */etc/prometheus/prometheus.yml* dosyasına aşağıdaki kodu ekliyoruz.

````sh
sudo nano /etc/prometheus/prometheus.yml
````

````sh 
- job_name: jenkins
  metrics_path: "/prometheus"
  static_configs:
    - targets: ["localhost:8080"]
````

![alt text](prometheus.yml-1.png)

![alt text](prometheus-jenkins-job.png)


## node_expporter kurulumu:

prometheus için metrik toplaması için kuruyoruz

![alt text](<node_exporter yükleme.png>)


jenkins server'ın metriklerini alabilmesi için prometheus.yaml dosyasına node_exporter url'ini ekliyoruz:

````sh
sudo nano /etc/prometheus/prometheus.yml
````
````sh
- job_name: node_export_jenkins
  static_configs:
    - targets: ["localhost:9100"]
````
![alt text](prometheus-jenkins-server-job.png)


````sh
sudo  systemctl restart prometheus
````

![alt text](prometheus-jenkins-server-job-2.png)


# Jenkins konfigürasyonu:

http://localhost:8080/ adresinden jenkins konsola bağlanıyoruz

ilk parolayı almak için terminalde şu kodu giriyoruz:

````sh
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
````

![alt text](<jenkins ilk parola alma.png>)

aldığımız parolayı buraya yapıştırıp devam ediyoruz.

![alt text](jenkins-1.png)

önerilen eklentileri yükleyi seçiyoruz.

![alt text](jenkins-2.png)

![alt text](jenkins-3.png)

kendi şifremizi belirliyoruz

![alt text](jenkins-4.png)



## Jenkins uygulamasındaki ayarlamalar:

### Pipeline'ı Çalıştırmak İçin Gerekli Plugin'ler

Jenkins üzerinde gerekli plugin'lerin kurulu olması gerekir.

Kurulum: Manage Jenkins > Manage Plugins > Available bölümüne 
      "Docker" 
      "AWS Credentials"
      "Terraform"
      "Prometheus metrics"

yazın ve yükleyin.


### pipeline post dımındaki email göderimi için jenkins ayarlamaları:

İzlenecek yol: *Jenkinsi yönet > Sistem > E-posta Bilgilendirmesi*

bu alana aşağıdaki gibi doldurmalıyız:

   SMTP server

    "smtp.gmail.com"

   Use SMTP Authentication?

    Username

    "mecit.tuksoy@gmail.com"

    Password

    "enter the password we saved"

    Check the "Use SSL" box

    SMTP Port?

     "465"

Gmail hesabımızdan uygulama şifresi alma:

![alt text](email-app-şifre-yeri.png)

![alt text](email-app-şifre.png)

![alt text](email-app-şifre-kaydet.png)

![alt text](email-jenkinse-giriş1.png)
![alt text](email-jenkinse-giriş2.png)


test ederek mailin geldiğini gördük
![alt text](email-doğrulama.png)

jenkinse email bilgilerimizi "global credentials" olarak  girmemiz gerekiyor.

![alt text](email-global-cred.png)

![alt text](email-jenkinse-giriş1-1.png)

*Kontrol Merkezi > Jenkins'i Yönet > Sistem > Extended E-mail Notification* bilgileri burayada girmemiz gerekiyor

![alt text](<email-sisteme girme.png>)

![alt text](<email-sisteme girme-2.png>)

![alt text](<email-sisteme girme-3.png>)


### jenkins server'da aws hesabımıza erişebilmek için jenkins kullanıcısına geçip "aws configure" yapıyoruz:

````sh
sudo su - jenkins
aws configure
  AWS Access Key ID [None]:
  AWS Secret Access Key [None]:
  Default region name [None]:
  Default output format [None]:
````

![alt text](<aws configure-1.png>)

### jenkins'in dockerhub'a image push edebilmesi için jenkins'e "docker credentials" bilgilerini girmeliyiz:

![alt text](docker-cred-1.png)
![alt text](docker-cred-2-1.png)
![alt text](docker-cred-3-1.png)
![alt text](docker-cred-4-1.png)


### jenkins pipeline'ı ayarlıyoruz:

1- Jenkins ana sayfasında "Yeni Öğe"'ye tıklayın.

2- Öğe adını girin.

3- "Pipeline" seçin.

4- "Build Triggers" tetikleyici oluşturma kısmından "GitHub hook trigger for GITScm polling" tik atın.

5- "Pipeline" altında "Definition" kısmında "SCM" yi "Git" seçin

6- "Repository URL" kısmına github repo url girin.

7- "Branch Specifier (blank for 'any')" kısmına hangi branch'da çalışmasını istiyorsanız yazabilirsiniz.

8- "Script Path" Jenkinsfile ismi farklı ise onu burada belirtmelisiniz.

9- "Kaydet" diyebiliriz.

![alt text](pipeline1-1.png)
![alt text](pipeline2-1.png)
![alt text](pipeline3-1.png)
![alt text](pipeline4-1.png)
![alt text](pipeline5-1.png)
![alt text](pipeline6-1.png)

