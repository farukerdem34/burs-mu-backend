Burs Eşleştirme Motoru - Backend Geliştirme Görevleri (Rust + Axum)

Bu belge, "Tek Bir İşi Çok İyi Yapma" prensibiyle tasarlanan Burs Eşleştirme Motorunun arka uç (backend) geliştirme sürecini tanımlar. Proje Rust dili ve Axum framework'ü kullanılarak monolitik bir mimaride inşa edilecektir. Veritabanı olarak Supabase (PostgreSQL) kullanılacaktır.

Görev 1: Proje Kurulumu ve Bağımlılıkların Yönetimi

Amaç: Proje iskeletini oluşturmak ve gerekli crate'leri (kütüphaneleri) tanımlamak.

[ ] cargo new scholarship-matcher komutu ile yeni bir Rust projesi başlat.

[ ] Cargo.toml dosyasına aşağıdaki bağımlılıkları ekle:

tokio (features: ["full"])

axum

sqlx (features: ["runtime-tokio-rustls", "postgres", "uuid", "chrono"])

serde (features: ["derive"])

serde_json

dotenvy (Çevresel değişkenleri okumak için)

uuid (features: ["v4", "serde"])

[ ] Projenin ana dizininde örnek bir .env.example dosyası oluştur ve gerekli anahtarları tanımla.

Görev 2: Çevresel Değişkenlerin (Environment) Yönetimi

Amaç: Hardcoded değerlerden kaçınarak, uygulamanın konfigürasyonunu .env dosyası üzerinden güvenli bir şekilde yönetmek.

[ ] .env dosyasında şu değişkenlerin tanımlanmasını sağla:

DATABASE_URL (Supabase PostgreSQL bağlantı dizesi)

SERVER_PORT (Örn: 8080)

WEIGHT_CITY (Şehir uyumunun skor ağırlığı, örn: 0.3)

WEIGHT_DEPARTMENT (Bölüm uyumunun skor ağırlığı, örn: 0.3)

WEIGHT_GPA (Not ortalaması uyumunun skor ağırlığı, örn: 0.2)

WEIGHT_INCOME (Gelir durumu uyumunun skor ağırlığı, örn: 0.2)

[ ] src/config.rs adında bir modül oluştur.

[ ] .env dosyasındaki değerleri okuyup parse eden ve uygulamanın her yerinde kullanılabilecek bir AppConfig struct'ı tanımla. Hatalı env değerlerinde uygulamanın panic! ile güvenli kapanmasını sağla.

Görev 3: Veritabanı Bağlantısı ve Uygulama Durumu (App State)

Amaç: Supabase (PostgreSQL) ile güvenilir ve asenkron bir bağlantı havuzu (connection pool) kurmak.

[ ] src/state.rs adında bir modül oluştur.

[ ] sqlx::PgPool kullanarak veritabanına bağlanacak fonksiyonu yaz.

[ ] İçerisinde db_pool: PgPool ve config: AppConfig barındıran bir AppState struct'ı oluştur.

[ ] Bu state'in Axum handler'larında (endpoint'lerde) güvenle paylaşılabilmesi için gerekli yapılandırmayı (örneğin Arc veya Axum'un yerleşik State çıkarımını) yap.

Görev 4: Veri Modellerinin (Structs) Tanımlanması

Amaç: Veritabanındaki şemayı (Öğrenci, Burs Kriterleri) Rust tarafında tip güvenli (type-safe) struct'lara dönüştürmek.

[ ] src/models.rs modülünü oluştur.

[ ] Veritabanındaki students tablosuna karşılık gelen Student struct'ını tanımla (Alanlar: profile_id, gpa, city, department, income_status).

[ ] Veritabanındaki scholarships tablosuna karşılık gelen ScholarshipRule struct'ını tanımla (Alanlar: id, min_gpa, target_cities, target_departments, target_income_levels).

[ ] SQL enum'ları ile Rust enum'larını (örneğin IncomeLevel) eşleştirmek için sqlx::Type derive makrolarını kullan.

Görev 5: Eşleştirme Motoru ve Skorlama Algoritması

Amaç: Projenin kalbi olan eşleştirme ve skor hesaplama mantığını kodlamak.

[ ] src/engine.rs modülünü oluştur.

[ ] calculate_match_score(student: &Student, rule: &ScholarshipRule, config: &AppConfig) -> Option<f32> imzasında bir fonksiyon yaz.

[ ] Eleyici Kural Mantığını Uygula: Fonksiyonun başında "Kesin Red" kriterlerini kontrol et. Eğer bağışçı target_cities belirtmişse ve öğrencinin city değeri bu listede yoksa, doğrudan None dön (Skor hesaplama, direkt ele). Aynı mantığı target_departments ve target_income_levels için de uygula. (Eğer hedef listeler boşsa, kural esnektir, herkesi kabul eder varsay).

[ ] Skorlama Mantığını Uygula: Eleyici kuralları geçen öğrenciler için bir skor hesapla.

Şehir, Bölüm ve Gelir uyumu varsa ilgili ağırlık (WEIGHT_...) kadar puan ver. (Örn: Uyuyorsa 100 * ağırlık, uymuyorsa 0).

GPA için oransal puanlama yap: (student.gpa / 4.0) * 100.0 * config.WEIGHT_GPA.

[ ] Toplam skoru hesapla ve dön.

Görev 6: API Endpoint'lerinin (Routes & Handlers) Yazılması

Amaç: Dışarıdan gelecek istekleri karşılayacak API uçlarını oluşturmak.

[ ] src/handlers.rs modülünü oluştur.

[ ] Endpoint: POST /match/:student_id

Bu endpoint'e istek geldiğinde (isteği yetkilendirilmiş bir istemcinin attığını varsayıyoruz, ilk etapta Auth middleware'i yok):

student_id parametresini al.

sqlx kullanarak Supabase'den sadece bu öğrencinin verisini çek.

Yine sqlx kullanarak aktif olan tüm burs kurallarını (scholarships) veritabanından çek. (Her istekte taze veri).

engine::calculate_match_score fonksiyonunu kullanarak öğrenciyi tüm burslarla döngü (iterator) içinde karşılaştır.

Eşleşenleri ve skorlarını bir vektörde topla.

Vektörü skora göre azalan (descending) şekilde sırala.

Sonuçları JSON formatında (Örn: [{ "scholarship_id": "...", "score": 85.5 }]) axum::Json olarak istemciye dön.

Görev 7: Main Fonksiyonunun Toparlanması

Amaç: Tüm modülleri bir araya getirip sunucuyu ayağa kaldırmak.

[ ] src/main.rs dosyasını düzenle.

[ ] Ortam değişkenlerini (AppConfig) yükle.

[ ] Veritabanı bağlantı havuzunu (PgPool) oluştur.

[ ] AppState'i oluştur.

[ ] Axum router'ını yapılandır ve oluşturulan handler'ları route'lara bağla. State'i router'a enjekte et.

[ ] tokio::net::TcpListener ile belirlenen port üzerinden sunucuyu dinlemeye başla ve gelen istekleri karşıla.
