#!/bin/bash
# Linux Honeypot Güvenlik Kurulum Scripti
# MacBook'a SSH bağlantısını engelle

echo "🔒 Honeypot Güvenlik Yapılandırması"
echo "===================================="
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# MacBook IP'sini al
read -p "MacBook IP adresi (örn: 192.168.1.50): " MACBOOK_IP

if [ -z "$MACBOOK_IP" ]; then
    echo -e "${RED}Hata: IP adresi gerekli!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}1. Firewall kuralı ekleniyor (outbound SSH engel)...${NC}"

# Mevcut kuralları kontrol et
if sudo iptables -L OUTPUT -n | grep -q "tcp dpt:22"; then
    echo -e "${YELLOW}Kural zaten var, atlanıyor.${NC}"
else
    # Yeni outbound SSH bağlantılarını engelle
    sudo iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW -j REJECT
    echo -e "${GREEN}✅ Firewall kuralı eklendi${NC}"
fi

# Kaydet
sudo apt install -y iptables-persistent
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections
sudo netfilter-persistent save

echo ""
echo -e "${YELLOW}2. SSH key kısıtlaması yapılandırılıyor...${NC}"
echo -e "${YELLOW}   authorized_keys dosyasını manuel düzenlemelisiniz:${NC}"
echo ""
echo "   nano ~/.ssh/authorized_keys"
echo ""
echo "   MacBook'un public key'inin BAŞINA ekleyin:"
echo "   ─────────────────────────────────────────────────"
echo '   command="rsync --server --sender",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAB3...'
echo "   ─────────────────────────────────────────────────"
echo ""

echo -e "${YELLOW}3. Read-only sync kullanıcısı oluşturuluyor...${NC}"

# Kullanıcı var mı kontrol et
if id "honeypot-sync" &>/dev/null; then
    echo -e "${YELLOW}honeypot-sync kullanıcısı zaten var.${NC}"
else
    sudo adduser --disabled-password --gecos "" honeypot-sync
    sudo usermod -s /usr/sbin/nologin honeypot-sync
    echo -e "${GREEN}✅ honeypot-sync kullanıcısı oluşturuldu${NC}"
fi

# Log dosyasına erişim
echo -e "${YELLOW}4. Log dosyası erişimi yapılandırılıyor...${NC}"

LOG_FILE="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

if [ -f "$LOG_FILE" ]; then
    sudo groupadd log-readers 2>/dev/null || true
    sudo usermod -aG log-readers honeypot-sync
    sudo chown cowrie:log-readers "$LOG_FILE"
    sudo chmod 640 "$LOG_FILE"
    echo -e "${GREEN}✅ Log dosyası erişimi yapılandırıldı${NC}"
else
    echo -e "${RED}⚠️  Log dosyası bulunamadı: $LOG_FILE${NC}"
fi

echo ""
echo -e "${GREEN}===================================="
echo "✅ Güvenlik yapılandırması tamamlandı!"
echo -e "====================================${NC}"
echo ""
echo "Test Adımları:"
echo "─────────────"
echo "1. Bu sunucudan MacBook'a SSH denemesi:"
echo "   ssh kullanici@${MACBOOK_IP}"
echo "   → Çalışmamalı! (Connection refused/timeout)"
echo ""
echo "2. MacBook'tan bu sunucuya rsync:"
echo "   ./secure_sync.sh"
echo "   → Çalışmalı!"
echo ""
echo "3. MacBook'tan SSH shell denemesi:"
echo "   ssh kullanici@$(hostname -I | awk '{print $1}')"
echo "   → Shell açmamalı, sadece rsync olmalı"
echo ""
