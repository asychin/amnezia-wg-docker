#!/bin/bash

# Скрипт выполняется при остановке интерфейса AmneziaWG

AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_NET=${AWG_NET:-10.13.13.0/24}

echo "[$(date)] Очистка правил маршрутизации для $AWG_INTERFACE"

# Удаление правил iptables
iptables -t nat -D POSTROUTING -s ${AWG_NET} -o eth+ -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -i ${AWG_INTERFACE} -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -o ${AWG_INTERFACE} -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i ${AWG_INTERFACE} -o ${AWG_INTERFACE} -j ACCEPT 2>/dev/null || true

echo "[$(date)] Правила маршрутизации очищены для $AWG_INTERFACE"
