# Pipeline ile neler yapıldı?

1. Environment Bölümü hazırlandı
PYTHON_PATH: Python 3'ün bulunduğu dizin yolu (Linux/Unix tarzı).
ETL_SCRIPT_PATH: Çalıştırılacak Python ETL betiğinin tam yolu.
CRON_LOG_PATH: Cron job'ının çıktılarını yazacağı log dosyasının yolu.
CRON_LOG_OUTPUT_FILE: Cron job'ının çıktısının yazılacağı dosya (email için ek olarak kullanılacak).

2. Python Environment Check
Amaç: Python 3'ün sistemde kurulu olup olmadığını kontrol eder.
sh("which ${env.PYTHON_PATH}") komutuyla Python 3'ün kurulu olup olmadığı kontrol edilir. Eğer Python bulunamazsa, hata verilir ve işlem durdurulur.
Eğer Python bulunursa, versiyonu ekrana yazdırılır.

3. Run ETL.py
Amaç: Belirtilen Python ETL betiğini çalıştırmak ve çıktılarını bir log dosyasına (cron.log) yazdırmaktır.
sh "\"${env.PYTHON_PATH}\" \"${env.ETL_SCRIPT_PATH}\" >> \"${env.CRON_LOG_PATH}\"" komutu ile belirtilen ETL betiği çalıştırılır ve çıktıları belirtilen log dosyasına yönlendirilir.

4. Setup Cron Job
Amaç: Bir cron job'ı yapılandırmak.
Cron job'ı, her dakika ETL.py betiğini çalıştıracak şekilde ayarlanır.
writeFile(file: '/tmp/mycron', text: cronJob) komutu ile cron job'ı geçici bir dosyaya yazılır.
sh("crontab /tmp/mycron") komutu ile cron job'ı aktif hale getirilir.

5. Verify Cron Job Output
Amaç: Cron job'ının çıktısını kontrol etmek ve log dosyasını incelemektir.
sh("sleep 3660") komutu ile 70 saniye beklenir, böylece cron job'ı çalışacak kadar zaman tanınır.
fileExists(env.CRON_LOG_PATH) ile cron log dosyasının varlığı kontrol edilir.
Eğer log dosyası varsa, sh("tail -n 1 \"${env.CRON_LOG_PATH}\" > \"${env.CRON_LOG_OUTPUT_FILE}\"") komutuyla log dosyasının son satırı bir dosyaya yazılır.
Log dosyasının toplam satır sayısı sh("wc -l < \"${env.CRON_LOG_PATH}\"") komutuyla hesaplanır.

6. Post Bölümü
Amaç: Pipeline tamamlandıktan sonra bir e-posta gönderilmesi sağlanır.
emailext komutu kullanılarak e-posta gönderilir.
E-posta içeriği, pipeline'ın sonucu, proje adı, build numarası ve URL ile birlikte, cron job'ının çıktısı (ek olarak) eklenir.
attachmentsPattern: "${CRON_LOG_OUTPUT_FILE}" ile cron job'ı çıktısı dosyası eklenir.





# Pipeline kullanmadan yapmak için:

## *ETL.py* dosyasının olduğu yolu almak için:

````sh
pwd
````
Benim çıktım aşağıdaki gibiydi:
````sh
/mnt/c/Users/MCT/Desktop/2N_TECH/2n DevOps CASE FİNALLY-çalışma/mern-project-k8s'li github repo/microservice-MERN-stack-deploy/python-project
````
*ETL.py* dosyası çalıştırılabilir bir dosyamı kontrol ediyorum:

````sh
ll  # çıktısı aşağıdaki gibi:
total 0
drwxrwxrwx 1 mecit mecit 4096 Dec  1 18:06 ./
drwxrwxrwx 1 mecit mecit 4096 Dec  1 17:39 ../
-rwxrwxrwx 1 mecit mecit  104 Nov 19 12:07 ETL.py*
-rwxrwxrwx 1 mecit mecit  658 Dec  1 18:31 README.md*
-rwxrwxrwx 1 mecit mecit    0 Dec  1 18:21 cron.log*
````

Çalıştırılabilir bir dosya olduğunu görüyorum. Eğer böyle olmasaydı *chmod +x* yapmamız gerekirdi.

## python3 yolunu bulmak için;

```sh
which python3 
```

çıktı:
```sh
/usr/bin/python3
```

## Cron job yapılandırmasını açmak için:

````sh
crontab -e
````

Açılan ekranda *ETL.py* dosyamızın her saat başı çalışması ve çıktıları yine aynı dosya yolunda *cron.log* dosyasının içine yazması için şu kodu giriyoruz:

````sh
1 * * * * /usr/bin/python3 "/mnt/c/Users/MCT/Desktop/2N_TECH/2n DevOps CASE FİNALLY-çalışma/mern-project-k8s'li github repo/microservice-MERN-stack-deploy/python-project/ETL.py" >> "/mnt/c/Users/MCT/Desktop/2N_TECH/2n DevOps CASE FİNALLY-çalışma/mern-project-k8s'li github repo/microservice-MERN-stack-deploy/python-project/cron.log"
````

cron.log dosyamda 2 saatte şunlar oluşmuş oldu:

````sh
<Response [200]>
{'current_user_url': 'https://api.github.com/user', 'current_user_authorizations_html_url': 'https://github.com/settings/connections/applications{/client_id}', 'authorizations_url': 'https://api.github.com/authorizations', 'code_search_url': 'https://api.github.com/search/code?q={query}{&page,per_page,sort,order}', 'commit_search_url': 'https://api.github.com/search/commits?q={query}{&page,per_page,sort,order}', 'emails_url': 'https://api.github.com/user/emails', 'emojis_url': 'https://api.github.com/emojis', 'events_url': 'https://api.github.com/events', 'feeds_url': 'https://api.github.com/feeds', 'followers_url': 'https://api.github.com/user/followers', 'following_url': 'https://api.github.com/user/following{/target}', 'gists_url': 'https://api.github.com/gists{/gist_id}', 'hub_url': 'https://api.github.com/hub', 'issue_search_url': 'https://api.github.com/search/issues?q={query}{&page,per_page,sort,order}', 'issues_url': 'https://api.github.com/issues', 'keys_url': 'https://api.github.com/user/keys', 'label_search_url': 'https://api.github.com/search/labels?q={query}&repository_id={repository_id}{&page,per_page}', 'notifications_url': 'https://api.github.com/notifications', 'organization_url': 'https://api.github.com/orgs/{org}', 'organization_repositories_url': 'https://api.github.com/orgs/{org}/repos{?type,page,per_page,sort}', 'organization_teams_url': 'https://api.github.com/orgs/{org}/teams', 'public_gists_url': 'https://api.github.com/gists/public', 'rate_limit_url': 'https://api.github.com/rate_limit', 'repository_url': 'https://api.github.com/repos/{owner}/{repo}', 'repository_search_url': 'https://api.github.com/search/repositories?q={query}{&page,per_page,sort,order}', 'current_user_repositories_url': 'https://api.github.com/user/repos{?type,page,per_page,sort}', 'starred_url': 'https://api.github.com/user/starred{/owner}{/repo}', 'starred_gists_url': 'https://api.github.com/gists/starred', 'topic_search_url': 'https://api.github.com/search/topics?q={query}{&page,per_page}', 'user_url': 'https://api.github.com/users/{user}', 'user_organizations_url': 'https://api.github.com/user/orgs', 'user_repositories_url': 'https://api.github.com/users/{user}/repos{?type,page,per_page,sort}', 'user_search_url': 'https://api.github.com/search/users?q={query}{&page,per_page,sort,order}'}
<Response [200]>
{'current_user_url': 'https://api.github.com/user', 'current_user_authorizations_html_url': 'https://github.com/settings/connections/applications{/client_id}', 'authorizations_url': 'https://api.github.com/authorizations', 'code_search_url': 'https://api.github.com/search/code?q={query}{&page,per_page,sort,order}', 'commit_search_url': 'https://api.github.com/search/commits?q={query}{&page,per_page,sort,order}', 'emails_url': 'https://api.github.com/user/emails', 'emojis_url': 'https://api.github.com/emojis', 'events_url': 'https://api.github.com/events', 'feeds_url': 'https://api.github.com/feeds', 'followers_url': 'https://api.github.com/user/followers', 'following_url': 'https://api.github.com/user/following{/target}', 'gists_url': 'https://api.github.com/gists{/gist_id}', 'hub_url': 'https://api.github.com/hub', 'issue_search_url': 'https://api.github.com/search/issues?q={query}{&page,per_page,sort,order}', 'issues_url': 'https://api.github.com/issues', 'keys_url': 'https://api.github.com/user/keys', 'label_search_url': 'https://api.github.com/search/labels?q={query}&repository_id={repository_id}{&page,per_page}', 'notifications_url': 'https://api.github.com/notifications', 'organization_url': 'https://api.github.com/orgs/{org}', 'organization_repositories_url': 'https://api.github.com/orgs/{org}/repos{?type,page,per_page,sort}', 'organization_teams_url': 'https://api.github.com/orgs/{org}/teams', 'public_gists_url': 'https://api.github.com/gists/public', 'rate_limit_url': 'https://api.github.com/rate_limit', 'repository_url': 'https://api.github.com/repos/{owner}/{repo}', 'repository_search_url': 'https://api.github.com/search/repositories?q={query}{&page,per_page,sort,order}', 'current_user_repositories_url': 'https://api.github.com/user/repos{?type,page,per_page,sort}', 'starred_url': 'https://api.github.com/user/starred{/owner}{/repo}', 'starred_gists_url': 'https://api.github.com/gists/starred', 'topic_search_url': 'https://api.github.com/search/topics?q={query}{&page,per_page}', 'user_url': 'https://api.github.com/users/{user}', 'user_organizations_url': 'https://api.github.com/user/orgs', 'user_repositories_url': 'https://api.github.com/users/{user}/repos{?type,page,per_page,sort}', 'user_search_url': 'https://api.github.com/search/users?q={query}{&page,per_page,sort,order}'}
````

## cron job sonlandırmak için:

```` crontab -e ```` ile yapılandırma sayfasını açıp ilgili tanımladığımız işin başına '#' koyarak yorum satırı haline getirebiliriz yada işi silerek kaydedip çıkabiliriz.


cron job listesini görüntülemek için ```` crontab -l ```` kullanabiliriz.