#!/bin/bash
# Cowrie SSH/Telnet Honeypot Kurulum Scripti
# Ubuntu/Debian için

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🐝 Cowrie Honeypot Kurulum                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Root kontrolü
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Bu scripti root olarak çalıştırmayın!${NC}"
    echo "Normal kullanıcı ile çalıştırın: bash cowrie_kurulum.sh"
    exit 1
fi

echo -e "${YELLOW}1. Sistem paketleri güncelleniyor...${NC}"
sudo apt update
sudo apt install -y git python3-virtualenv libssl-dev libffi-dev build-essential \
    libpython3-dev python3-minimal authbind

echo ""
echo -e "${YELLOW}2. Cowrie kullanıcısı oluşturuluyor...${NC}"
if id "cowrie" &>/dev/null; then
    echo -e "${GREEN}cowrie kullanıcısı zaten var.${NC}"
else
    sudo adduser --disabled-password --gecos "" cowrie
    echo -e "${GREEN}✅ cowrie kullanıcısı oluşturuldu${NC}"
fi

echo ""
echo -e "${YELLOW}3. Cowrie indiriliyor...${NC}"
sudo su - cowrie -c "
    if [ -d cowrie ]; then
        echo 'Cowrie zaten indirilmiş, güncelleniyor...'
        cd cowrie && git pull
    else
        git clone http://github.com/cowrie/cowrie
        cd cowrie
    fi
"

echo ""
echo -e "${YELLOW}4. Python sanal ortamı kuruluyor...${NC}"
sudo su - cowrie -c "
    cd cowrie
    python3 -m venv cowrie-env
    source cowrie-env/bin/activate
    pip install --upgrade pip
    pip install --upgrade -r requirements.txt
"

echo ""
echo -e "${YELLOW}5. Cowrie yapılandırılıyor...${NC}"
sudo su - cowrie -c "
    cd cowrie
    cp etc/cowrie.cfg.dist etc/cowrie.cfg
    
    # JSON logging aktif et
    sed -i 's/^#logfile = log\/cowrie.json/logfile = var\/log\/cowrie\/cowrie.json/' etc/cowrie.cfg
    
    # Hostname ayarla
    sed -i 's/^hostname = svr04/hostname = prod-server-01/' etc/cowrie.cfg
    
    # Log dizini oluştur
    mkdir -p var/log/cowrie
"

echo ""
echo -e "${YELLOW}6. SSH port yönlendirmesi (Port 22 → 2222)...${NC}"
echo "Cowrie 2222 portunda çalışacak."
echo "Port 22'yi yönlendirmek için authbind veya iptables kullanabilirsiniz."
echo ""
echo "Seçenek 1 - iptables (önerilen):"
echo "  sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222"
echo "  sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223"
echo "  sudo apt install iptables-persistent"
echo "  sudo netfilter-persistent save"
echo ""
echo "Seçenek 2 - authbind:"
echo "  sudo touch /etc/authbind/byport/22"
echo "  sudo chown cowrie:cowrie /etc/authbind/byport/22"
echo "  sudo chmod 770 /etc/authbind/byport/22"
echo ""

read -p "iptables ile port yönlendirmesi yapılsın mı? (y/n): " SETUP_IPTABLES

if [ "$SETUP_IPTABLES" = "y" ] || [ "$SETUP_IPTABLES" = "Y" ]; then
    echo -e "${YELLOW}Port yönlendirmesi yapılıyor...${NC}"
    
    # Mevcut kuralları kontrol et
    if sudo iptables -t nat -L | grep -q "2222"; then
        echo -e "${YELLOW}Port yönlendirmesi zaten var.${NC}"
    else
        sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
        sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223
        echo -e "${GREEN}✅ Port yönlendirmesi eklendi${NC}"
    fi
    
    # Kaydet
    sudo apt install -y iptables-persistent
    echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections
    echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections
    sudo netfilter-persistent save
    echo -e "${GREEN}✅ iptables kuralları kaydedildi${NC}"
fi

echo ""
echo -e "${YELLOW}7. Systemd servisi oluşturuluyor...${NC}"
sudo tee /etc/systemd/system/cowrie.service > /dev/null << 'EOF'
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
Type=forking
User=cowrie
Group=cowrie
WorkingDirectory=/home/cowrie/cowrie
ExecStart=/home/cowrie/cowrie/bin/cowrie start
ExecStop=/home/cowrie/cowrie/bin/cowrie stop
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cowrie
echo -e "${GREEN}✅ Systemd servisi oluşturuldu${NC}"

echo ""
echo -e "${YELLOW}8. Cowrie başlatılıyor...${NC}"
sudo systemctl start cowrie
sleep 3

if sudo systemctl is-active --quiet cowrie; then
    echo -e "${GREEN}✅ Cowrie başarıyla başlatıldı!${NC}"
else
    echo -e "${RED}❌ Cowrie başlatılamadı!${NC}"
    echo "Logları kontrol edin: sudo journalctl -u cowrie -f"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ COWRIE KURULUM TAMAMLANDI!                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Bilgiler:"
echo "  • Honeypot Portu: 2222 (SSH), 2223 (Telnet)"
echo "  • Gerçek SSH Portu: Port 22 honeypot'a yönlendiriliyor"
echo "  • Log Dosyası: /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo "  • Kullanıcı: cowrie"
echo ""
echo "🔧 Komutlar:"
echo "  • Durum: sudo systemctl status cowrie"
echo "  • Başlat: sudo systemctl start cowrie"
echo "  • Durdur: sudo systemctl stop cowrie"
echo "  • Loglar: sudo journalctl -u cowrie -f"
echo "  • Cowrie log: tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "🧪 Test:"
echo "  • Başka bir makineden: ssh root@BU_SUNUCU_IP"
echo "  • Parola dene: password123"
echo "  • Komutlar: ls, whoami, cat /etc/passwd"
echo ""
echo "⚠️  Gerçek SSH'a bağlanmak için:"
echo "  • Port 2222'yi kullan: ssh -p 2222 kullanici@localhost"
echo "  • Veya başka bir port aç ve firewall'da izin ver"
echo ""
echo "🔒 Güvenlik:"
echo "  • Sırada: bash GUVENLIK_KURULUM.sh (MacBook bağlantı güvenliği)"
echo ""

