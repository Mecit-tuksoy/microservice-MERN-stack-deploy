1. client/src içinde:

API çağrılarında kullanılan dosyalar: Eğer bir axios veya fetch ile backend'e çağrı yapıyorsanız, bu dosyalarda API URL’lerini tanımlıyor olabilirsiniz. Örneğin:
client/src/components/*.js (örn: recordList.js, create.js, edit.js)
client/src/App.js (Global bir çağrı yapılıyorsa)

backend-service:30001
frontend-service:30002
# url olan dosyalar:
client/src/components/create.js >> localhost:5050
client/src/components/edit.js >> localhost:5050     >>2 yerde var
client/src/components/healtcheck.js >> localhost:5050  
client/src/components/recordList.js >> localhost:5050   >>2 yerde var
client/cypress/integration/endToEnd.spec.js  >> localhost:3000   >>>3 yerde var
server/db/conn.msj >>> localhost:27017  
server/.env-example  >>> bu dosyada "ATLAS_URI=" var buraya mongodbnin url gelecek  >>>
örnek: ATLAS_URI=mongodb://admin:secret@mongodb:27017/sample_training?authSource=admin
client/cypress.json da "baseUrl": "http://localhost:3000" kısmını unutma 


# mongodb container çalıştır

````sh
docker run -d \
  --name mongodb \
  --network mern-network \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  -e MONGO_INITDB_DATABASE=sample_training \
  -p 27017:27017 \
  mongo:5.0
````

# backend containeri çalıştır:
````sh
docker run -d \
  --name mern-backend \
  --network mern-network \
  -p 5050:5050 \
  -e ATLAS_URI=mongodb://admin:secret@mongodb:27017/sample_training?authSource=admin \
  --link mongodb \
  mecit35/mern-project-backend
````


# Test Sonuçlarını Değerlendirme

Cypress testleri tamamlandıktan sonra test sonuçlarına, test raporlarına veya terminal çıktısına erişmek için Cypress Dashboard veya terminal logları üzerinden kontrol sağlayabilirsiniz.



1. Backend (server)
   
- server/db/conn.mjs: Veritabanı bağlantı URI'si.
- server/server.mjs:
CORS politikası varsa frontend URL'sini kontrol edin.
Dinlenecek host ve port numarasını burada tanımlıyor olabilirsiniz.
- 



# Healthcheck Endpoint'ini Test Edin:

curl http://localhost:5050/healthcheck

curl http://backend-service:5050/healthcheck   >>>minikubede yanıt geldi

Beklenen Yanıt:
{
  "uptime": 123.456,
  "message": "OK",
  "timestamp": 1695745396
}

# Database ile Bağlantıyı Test Edin:

Yeni bir kayıt eklemek:
````sh
curl -X POST -H "Content-Type: application/json" \
-d '{"name": "Mecit", "position": "DevOps", "level": "Middle"}' \
http://backend-service:5050/record     
````  
>>> >>>docker-compose ile bu çalışıyor


# Kayıtları listelemek:

curl http://backend-service:5050/record    >>>docker-compose ile bu çalışıyor


# kubeconfig:
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster

# kubectl control:

kubectl version --client


# aws kimlik bilgilerini tanımla:
Jenkins ana sayfasına git.
Manage Jenkins → Manage Credentials → Global Credentials.
Add Credentials ile aşağıdaki değerleri gir:
AWS Access Key ID: IAM kullanıcısına ait access key.
AWS Secret Access Key: Secret key.