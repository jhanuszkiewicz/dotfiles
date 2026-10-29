#!/bin/bash
# cpu - every 2 s the averaged % + icon color, grey normally, yellow from 50%, red from 80%
# ram - used GB like activity monitor (app + wired + compressed),
# grey normally, yellow from 75% of the total, red from 90%

. "$CONFIG_DIR/colors.sh"

# popup open (cpu_click.sh) = mouse leaving closes it, otherwise refresh its list too
plik="/tmp/sketchybar_cpu_$USER"
tryb=$(cat "$plik" 2>/dev/null)
case "$SENDER" in
  mouse.exited.global)
    echo off > "$plik"
    sketchybar --set cpu_icon popup.drawing=off
    exit 0 ;;
esac

# lazy cpu: exponential moving average per process name, time constant 15 s
# (a jump shows ~63% after 15 s, almost fully after ~45 s), kept in $sredn
# as "#t<TAB>last time" + "avg<TAB>name" lines; cpu_top.sh reads it for the list
# the bar % = sum of the averages / cores
sredn="/tmp/sketchybar_cpu_avg_$USER"
rdzenie=$(sysctl -n hw.ncpu)
proc=$(ps -Aco pcpu=,comm= | awk -v plik="$sredn" -v now="$(date +%s)" -v tau=15 -v r="$rdzenie" '
  BEGIN {
    while ((getline l < plik) > 0) {
      split(l, f, "\t")
      if (f[1] == "#t") t = f[2]; else sr[f[2]] = f[1]
    }
    close(plik)
    a = t ? 1 - exp(-(now - t) / tau) : 1
  }
  { n = $0; sub(/^ *[0-9.]+ /, "", n); cur[n] += $1; sr[n] += 0 }
  END {
    tmp = plik ".tmp"
    printf "#t\t%d\n", now > tmp
    for (n in sr) {
      v = sr[n] + a * (cur[n] - sr[n])
      if (v < 0.05) continue
      printf "%.2f\t%s\n", v, n > tmp
      s += v
    }
    close(tmp)
    system("mv \"" tmp "\" \"" plik "\"")
    printf "%d", s / r
  }')
if [ "$proc" -gt 100 ]; then
  proc=100
fi

kolor=$GREY
tkolor=$FG2
if [ "$proc" -ge 80 ]; then
  kolor=$RED
  tkolor=$RED
elif [ "$proc" -ge 50 ]; then
  kolor=$YELLOW
  tkolor=$YELLOW
fi

read -r ram rkolor < <(vm_stat | awk -v tot="$(sysctl -n hw.memsize)" \
  -v g="$GREY" -v y="$YELLOW" -v r="$RED" '
  /page size of/ { ps = $8 }
  /^Anonymous pages/ { a = $3 }
  /^Pages purgeable/ { p = $3 }
  /^Pages wired down/ { w = $4 }
  /^Pages occupied by compressor/ { c = $5 }
  END {
    u = (a - p + w + c) * ps
    k = g
    if (u >= tot * 0.9) k = r
    else if (u >= tot * 0.75) k = y
    printf "%.1fG %s", u / 1024^3, k
  }')

sketchybar --set cpu_icon icon.color=$kolor label="${proc}%" label.color=$tkolor \
  --set ram label="$ram" label.color=$rkolor

case "$tryb" in
  cpu|ram) "$CONFIG_DIR/plugins/cpu_top.sh" "$tryb" ;;
esac
