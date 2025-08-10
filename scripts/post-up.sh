#!/bin/bash

# Скрипт выполняется при поднятии интерфейса AmneziaWG

AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_NET=${AWG_NET:-10.13.13.0/24}

echo "[$(date)] Настройка маршрутизации для $AWG_INTERFACE"

# Включение IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Настройка iptables для NAT
iptables -t nat -A POSTROUTING -s ${AWG_NET} -o eth0 -j MASQUERADE
iptables -A FORWARD -i ${AWG_INTERFACE} -j ACCEPT
iptables -A FORWARD -o ${AWG_INTERFACE} -j ACCEPT

# Настройка дополнительных правил для безопасности
iptables -A FORWARD -i ${AWG_INTERFACE} -o ${AWG_INTERFACE} -j ACCEPT

echo "[$(date)] Маршрутизация настроена для $AWG_INTERFACE"
