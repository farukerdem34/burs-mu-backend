# Düzeltildi

1. ~~Yönetici hesabı 401 hatası almakta, her yerde~~
   - **Sebep**: Dio interceptor'ı async olarak `flutter_secure_storage`'dan token okuyor, ancak Dio 5.x'te async interceptor'lar güvenilir şekilde çalışmıyor. İstek, SecureStorage okuması tamamlanmadan önce gönderilebiliyor, bu da Bearer header'ının eksik olmasına ve 401 hatasına yol açıyordu.
   - **Çözüm**: Token artık her istekte SecureStorage'dan okunmak yerine `ApiClient` içinde static bir değişkende (bellekte) tutuluyor. Login/register sonrası ve uygulama başlangıcında (`_checkSession`) set ediliyor, logout'ta temizleniyor. Dio interceptor'ı artık senkron ve güvenilir.

2. ~~Android telefonlarda "Geri Dön", "Ana Menüye Dön", "Tüm Uygulamaları Gör" butonları bazı componentlerin görünmesini engelliyor.~~
   - **Sebep**: Hiçbir ekranda `SafeArea` kullanılmamış. Sadece 2/16 ekranda kısmi SafeArea vardı. Android navigasyon çubuğu içeriğin alt kısmını kapatıyordu.
   - **Çözüm**: `app.dart`'daki tüm uygulama içeriği `SafeArea` ile sarıldı. Artık her ekran sistem UI çentiklerine otomatik uyum sağlıyor.
