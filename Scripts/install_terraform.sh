#!/bin/bash

# Terraform'un en son sürümünü kontrol et ve doğrula
echo "Terraform'un en son sürümü kontrol ediliyor..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

if [[ -z "$LATEST_VERSION" ]]; then
  echo "Terraform'un en son sürümü alınamadı. Lütfen bağlantınızı kontrol edin."
  exit 1
fi

echo "Bulunan son sürüm: $LATEST_VERSION"

# Sürümden "v" karakterini kaldır
VERSION_NUMBER=${LATEST_VERSION#v}

# İndirilecek dosya adı ve link
TERRAFORM_ZIP="terraform_${VERSION_NUMBER}_linux_amd64.zip"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${VERSION_NUMBER}/${TERRAFORM_ZIP}"

# Geçici bir dizin oluştur ve indir
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

echo "Terraform $VERSION_NUMBER indiriliyor..."
curl -fLO $DOWNLOAD_URL

if [[ $? -ne 0 ]]; then
  echo "Terraform indirilirken bir hata oluştu. Lütfen bağlantınızı kontrol edin."
  rm -rf $TEMP_DIR
  exit 1
fi

# İndirilen dosyayı aç ve binary'yi /usr/local/bin'e taşı
echo "Terraform kuruluyor..."
unzip $TERRAFORM_ZIP
if [[ $? -ne 0 ]]; then
  echo "Dosya açılırken bir hata oluştu. İndirilen dosya bozuk olabilir."
  rm -rf $TEMP_DIR
  exit 1
fi

sudo mv terraform /usr/local/bin/

# Geçici dosyaları temizle
cd ~
rm -rf $TEMP_DIR

# Yüklemeyi kontrol et
echo "Terraform yükleme tamamlandı. Sürüm bilgisi:"
terraform -version
