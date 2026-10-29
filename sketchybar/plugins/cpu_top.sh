#!/bin/bash
# fills the cpu popup with the 5 hungriest processes, $1 = cpu | ram
# processes with the same name are summed (zen tabs = many plugin-container),
# cpu is the lazy average from cpu.sh, ram is the current rss
#   top cpu
#   plugin-container    90.3%
#   WindowServer        43.6%

if [ "$1" = "ram" ]; then
  sketchybar --set cpu.top label="top ram"
  rows=$(ps -Aco rss=,comm= | awk '
    { n = $0; sub(/^ *[0-9]+ /, "", n); s[n] += $1 }
    END { for (n in s) printf "%d\t%s\n", s[n], n }' | sort -rn | head -5 |
    awk -F'\t' '{ printf "%-20.20s %6.1fG\n", $2, $1 / 1024^2 }')
else
  sketchybar --set cpu.top label="top cpu"
  # 15 s averages cpu.sh keeps, so the list doesn't jump either
  rows=$(grep -v '^#t' "/tmp/sketchybar_cpu_avg_$USER" | sort -rn | head -5 |
    awk -F'\t' '{ printf "%-20.20s %6.1f%%\n", $2, $1 }')
fi

args=()
i=1
while IFS= read -r row
do
  args+=(--set cpu.p$i label="$row")
  i=$(( i + 1 ))
done <<< "$rows"
sketchybar "${args[@]}"
