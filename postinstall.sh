#!/bin/bash

echo "[INFO] Début du post-install OVH pour Proxmox"

# 1. Mettre à jour le système
apt update && apt full-upgrade -y

# 2. Dépôt non-subscription Proxmox (si c'est une installation Proxmox)
if grep -q "proxmox" /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "[INFO] Remplacement du dépôt enterprise par non-subscription"
    sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
    apt update
    apt dist-upgrade -y
fi

# 3. Installer outils utiles
apt install -y sudo curl wget htop unzip net-tools vim fail2ban ufw

# 4. Sécuriser SSH
echo "[INFO] Sécurisation SSH"
sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh

# 5. Activer le pare-feu UFW
echo "[INFO] Activation du pare-feu UFW"
ufw allow 2222/tcp
ufw allow 8006/tcp  # Interface Proxmox
ufw --force enable

# 6. Activer fail2ban
systemctl enable fail2ban --now

echo "[INFO] Post-installation terminée avec succès."
