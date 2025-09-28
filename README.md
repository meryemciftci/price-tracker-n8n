# 🛒 E-ticaret Fiyat Takipçisi (N8N)

N8N ile geliştirilmiş otomatik e-ticaret fiyat takip sistemi.  
Trendyol, Hepsiburada gibi sitelerden ürün fiyatlarını çekerek **MySQL veritabanına kaydeder**.  
Docker üzerinde kolayca ayağa kalkar, yeni site/ürün eklemek oldukça basittir.

---

## 🚀 Özellikler
- **Otomatik Fiyat Takibi** → Belirlenen aralıklarla ürün fiyatlarını kontrol eder  
- **Çoklu Site Desteği** → Trendyol, Hepsiburada, Amazon vb.  
- **Veritabanı Kaydı** → Fiyat geçmişini MySQL veritabanında saklar  
- **Web Scraping** → CSS selector’ları ile fiyat bilgisini çıkarır  
- **Esnek Yapı** → Yeni siteler ve ürünler kolayca eklenebilir  

---

## 🧰 Teknoloji Stack
- [N8N](https://n8n.io/) → Workflow automation  
- **MySQL** → Veritabanı  
- **Docker & Docker Compose** → Containerization  
- **PhpMyAdmin** → Veritabanı yönetimi  
- **JavaScript** → Fiyat çıkarma ve veri işleme  

---

## 🔄 N8N Workflow’ları
**Workflow Yapısı:**  
`Schedule Trigger → MySQL (Ürünleri Getir) → Split In Batches → HTTP Request → Code (Fiyat Çıkar) → MySQL (Fiyat Kaydet)`

### 🧩 Node Açıklamaları
- **Schedule Trigger** → Belirlenen aralıklarla tetikleme  
- **MySQL Select** → Aktif ürünleri veritabanından çekme  
- **Split In Batches** → Her ürünü tek tek işleme  
- **HTTP Request** → Ürün sayfasını GET ile çekme  
- **Code** → HTML içinden fiyatı selector ile çıkarma, temizleme (`parseFloat` vb.)  
- **MySQL Insert** → Çekilen fiyatı veritabanına kaydetme  

---

## 📸 Workflow Görseli
![Workflow](https://github.com/user-attachments/assets/3cf1f52c-9b14-4fa9-a6eb-37bec94dbda7)

---

## ⚙️ Kurulum
```bash
git clone https://github.com/[kullanici-adin]/price-tracker-n8n.git
cd price-tracker-n8n
docker-compose up -d
