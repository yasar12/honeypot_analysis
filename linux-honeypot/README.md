# 🐧 Linux Honeypot Sunucu Kurulumu

Bu klasör **Linux honeypot sunucusuna** kurulacak dosyaları içerir.

---

## 📦 İÇERİK

```
deployment/linux-honeypot/
├── README.md                          # Bu dosya
├── GUVENLIK_KURULUM.sh               # Güvenlik yapılandırması
├── cowrie_kurulum.sh                  # Cowrie honeypot kurulumu
├── honeypot_setup_guide.md            # Detaylı kurulum rehberi
└── config/
    └── authorized_keys.example        # SSH key örneği (kısıtlı)
```

---

## 🎯 BU SUNUCUYA KURULACAKLAR

1. **Cowrie Honeypot** → SSH/Telnet saldırılarını yakala
2. **Firewall Kuralları** → MacBook'a outbound SSH engel
3. **Read-Only Sync Kullanıcısı** → Güvenli log erişimi
4. **SSH Key Kısıtlaması** → Sadece rsync izni

---

## 🚀 HIZLI KURULUM

### 1. Dosyaları Linux'a Kopyala

```bash
# MacBook'tan
cd ~/Desktop/smart_honeypot
scp -r deployment/linux-honeypot kullanici@LINUX_IP:~/honeypot-setup/
```

### 2. Linux'ta Kurulum

```bash
# Linux'a bağlan
ssh kullanici@LINUX_IP

# Kurulum klasörüne git
cd ~/honeypot-setup/linux-honeypot

# 1. Cowrie kur (SSH honeypot)
bash cowrie_kurulum.sh

# 2. Güvenlik yapılandırması
bash GUVENLIK_KURULUM.sh
# → MacBook IP'sini gir

# 3. authorized_keys düzenle
nano ~/.ssh/authorized_keys
# → config/authorized_keys.example'a bak
```

### 3. Test Et

```bash
# Linux'tan MacBook'a SSH (ÇALIŞMAMALI)
ssh kullanici@MACBOOK_IP
# ❌ Connection refused → BAŞARILI!

# MacBook'tan log çekme testi (MacBook'ta çalıştır)
./sync_logs.sh
# ✅ Çalışmalı → BAŞARILI!
```

---

## 📋 DETAYLI KURULUM

Detaylı adımlar için: `honeypot_setup_guide.md`

---

## 🔒 GÜVENLİK ÖZELLİKLERİ

✅ **Firewall:** Linux → MacBook SSH ENGELLİ  
✅ **SSH Key:** Sadece rsync için  
✅ **Shell:** Erişim YOK (no-pty)  
✅ **Kullanıcı:** Read-only sync kullanıcısı  

---

## 🛠️ SİSTEM GEREKSİNİMLERİ

- **İşletim Sistemi:** Ubuntu 20.04+, Debian 10+, CentOS 8+
- **RAM:** Minimum 1 GB
- **Disk:** 10 GB boş alan
- **Network:** İnternet bağlantısı + yerel ağ

---

## 📊 KURULUM SONRASI

```
✅ Cowrie çalışıyor → port 2222 (SSH)
✅ Loglar: /home/cowrie/cowrie/var/log/cowrie/cowrie.json
✅ MacBook log çekiyor → her 5 dakika (cron)
✅ Güvenlik aktif → Linux'tan MacBook'a bağlantı YOK
```

---

## 🆘 SORUN GİDERME

### Cowrie çalışmıyor
```bash
sudo systemctl status cowrie
sudo journalctl -u cowrie -f
```

### Firewall kontrol
```bash
sudo iptables -L OUTPUT -n | grep "tcp dpt:22"
```

### Log dosyası yok
```bash
ls -la /home/cowrie/cowrie/var/log/cowrie/
# Honeypot'a birkaç SSH denemesi yap
```

---

## 🔗 İLGİLİ DÖKÜMANLAR

- `honeypot_setup_guide.md` → Detaylı adımlar
- `../macos-analysis/README.md` → MacBook kurulumu
- `../../README_GUVENLIK.md` → Güvenlik rehberi

---

## ✅ KURULUM CHECKLİST

- [ ] Linux sunucu hazır
- [ ] Cowrie kuruldu
- [ ] Güvenlik yapılandırması tamam
- [ ] authorized_keys düzenlendi
- [ ] Linux'tan MacBook'a SSH ENGELLİ
- [ ] MacBook'tan log çekme çalışıyor
- [ ] Honeypot'a test saldırısı yapıldı
- [ ] Loglar MacBook'a geliyor

**Hepsi ✅ ise → SİSTEM HAZIR! 🎉**

