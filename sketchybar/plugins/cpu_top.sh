#!/bin/bash
# fills the cpu popup with the 5 hungriest processes, $1 = cpu | ram
# processes with the same name are summed (zen tabs = many plugin-container),
# cpu is the lazy average from cpu.sh, ram is the current memory footprint
#   top cpu
#   plugin-container    90.3%
#   WindowServer        43.6%

if [ "$1" = "ram" ]; then
  sketchybar --set cpu.top label="top ram"
  # memory footprint from top, like activity monitor: unlike rss it counts
  # compressed pages too (they can be several GB that no process's rss shows)
  # top cuts names at 16 chars, so names come from ps by pid
  # (wine apps have "C:\...\x.exe" names, the rows keep only the file name)
  rows=$( (ps -Aco pid=,comm=; echo "--"; top -l 1 -stats pid,mem) | awk '
    $0 == "--" { top = 1; next }
    !top { p = $1; n = $0; sub(/^ *[0-9]+ /, "", n); name[p] = n; next }
    $1 ~ /^[0-9]+$/ && ($1 in name) {
      m = $2; sub(/[+-]$/, "", m)
      u = substr(m, length(m)); v = m + 0
      if (u == "K") v /= 1024; else if (u == "G") v *= 1024; else if (u == "B") v /= 1024^2
      s[name[$1]] += v
    }
    END { for (n in s) printf "%.1f\t%s\n", s[n], n }' | sort -rn | head -5 |
    awk -F'\t' '{ sub(/.*[\\\/]/, "", $2); printf "%-20.20s %6.1fG\n", $2, $1 / 1024 }')
else
  sketchybar --set cpu.top label="top cpu"
  # 15 s averages cpu.sh keeps, so the list doesn't jump either
  rows=$(grep -v '^#t' "/tmp/sketchybar_cpu_avg_$USER" | sort -rn | head -5 |
    awk -F'\t' '{ sub(/.*[\\\/]/, "", $2); printf "%-20.20s %6.1f%%\n", $2, $1 }')
fi

args=()
i=1
while IFS= read -r row
do
  args+=(--set cpu.p$i label="$row")
  i=$(( i + 1 ))
done <<< "$rows"
sketchybar "${args[@]}"
