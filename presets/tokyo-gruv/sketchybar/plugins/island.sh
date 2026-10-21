#!/bin/bash
# notch island - one script for all events
#   volume, brightness, charger   -> built-in sketchybar events
#   failed compile                -> island_cmd (hook in zsh/island.zsh)
#   new song                      -> island_media (plugins/island_media.sh)
#   pomodoro                      -> island_pomodoro (scripts/pomodoro) + routine every 1 s
# normal events show up for a moment, pomodoro stays on the island until it ends
#
# look follows the rest of the bar: grey icon, bold number like the clock,
# dim words like the date, the same rounded slider as on the right side

. "$CONFIG_DIR/colors.sh"
export PATH=/opt/homebrew/bin:$PATH

NIC=0x00000000
CHWILA="/tmp/sketchybar_island_$USER"       # pid of the last short popup
POMO="$HOME/.cache/sketchybar/pomodoro"     # "start end" (seconds) while a pomodoro runs
PLASTRY=(󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥)  # circle slices, 1/8 ... 8/8
LOG="$HOME/.dotfiles/.debug/island.log"     # TEMP debug (delete later)

ZAPAS=15     # how far each half goes under the real notch (island_init.sh: NOTCH)
TOR=96       # slider length
F_ZWYKLY="JetBrainsMono Nerd Font:Medium:13.0"
F_GRUBY="JetBrainsMono Nerd Font:Bold:13.0"

sb() {
  sketchybar "$@" >> "$LOG" 2>&1
}

dlugosc() {
  perl -CSA -e 'print length($ARGV[0])' "$1"
}

# $1 icon  $2 icon color  $3 left text  $4 left color  $5 left font
# $6 right side: text, or "%NN" for a slider  $7 right color
otworz() {
  ikona=$1; k_ik=$2; lewy=$3; k_l=$4; f_l=$5; prawy=$6; k_p=$7

  # width of one half (both the same, so the island stays centered on the notch)
  # ~8.5 pt per letter of the 13 pt mono font + paddings, with a bit of room
  l=$(( 14 + 22 + 6 + $(dlugosc "$lewy") * 17 / 2 + 14 ))
  proc=""
  case "$prawy" in
    %*) proc=${prawy#%}; r=$(( 24 + TOR + 16 )) ;;
    *)  r=$(( 24 + $(dlugosc "$prawy") * 17 / 2 + 16 )) ;;
  esac
  w=$l
  [ $r -gt $w ] && w=$r
  [ $w -lt 120 ] && w=120
  [ $w -gt 250 ] && w=250

  # left: icon + text, the extra ZAPAS of label width hides under the notch
  ksztalt_l=(icon.padding_left=14 icon.width=22 icon.padding_right=6 label.width=$(( w - 42 + ZAPAS )))
  # right: text, or a slider made of icon.background (filled part) + label.background (rest)
  if [ -n "$proc" ]; then
    wyp=$(( TOR * proc / 100 ))
    [ $wyp -lt 3 ] && wyp=3
    ksztalt_r=(icon.padding_left=$(( 24 + ZAPAS )) icon.width=$wyp
               label.padding_left=0 label.width=$(( TOR - wyp )) label.padding_right=$(( w - 24 - TOR )))
    tresc_r=(icon.drawing=on icon=" " label=" " icon.background.drawing=on label.background.drawing=on)
    kolory_r=(icon.background.color=$FG2 label.background.color=$RAMKA label.color=$NIC)
  else
    ksztalt_r=(icon.padding_left=0 icon.width=0
               label.padding_left=$(( 24 + ZAPAS )) label.width=$(( w - 24 )) label.padding_right=0)
    tresc_r=(icon.drawing=off label="$prawy" icon.background.drawing=off label.background.drawing=off)
    kolory_r=(label.color=$k_p)
  fi

  if [ "$(sketchybar --query island.l | jq -r '.geometry.drawing')" = "on" ]; then
    # already open - new content and size, no fade
    sb --set island.l icon="$ikona" label="$lewy" label.font="$f_l" icon.color=$k_ik label.color=$k_l \
      --set island.r "${tresc_r[@]}" "${kolory_r[@]}" \
      --animate tanh 10 \
      --set island.l "${ksztalt_l[@]}" \
      --set island.r "${ksztalt_r[@]}"
  else
    # shape grows out of the notch first, the content fades in after it
    # (two values in one --animate = two steps one after another)
    przezr_r=(label.color=$NIC icon.background.color=$NIC label.background.color=$NIC)
    kroki_r=()
    for k in "${kolory_r[@]}"; do
      kroki_r+=("${k%%=*}=$NIC" "$k")
    done
    sb --set island.l drawing=on icon="$ikona" label="$lewy" label.font="$f_l" icon.color=$NIC label.color=$NIC \
      --set island.r drawing=on "${tresc_r[@]}" "${przezr_r[@]}" \
      --animate tanh 12 \
      --set island.l "${ksztalt_l[@]}" icon.color=$NIC icon.color=$k_ik label.color=$NIC label.color=$k_l \
      --set island.r "${ksztalt_r[@]}" "${kroki_r[@]}"
  fi
  echo "open w=$w l='$lewy' r='$prawy'" >> "$LOG"
}

zamknij() {
  # content fades out first, then the shape shrinks back into the notch
  sb --animate tanh 8 \
    --set island.l icon.color=$NIC label.color=$NIC \
    --set island.r label.color=$NIC icon.background.color=$NIC label.background.color=$NIC
  sleep 0.15
  [ -s "$CHWILA" ] && return   # something opened it again in the meantime
  sb --animate tanh 12 \
    --set island.l icon.padding_left=0 icon.width=0 icon.padding_right=0 label.width=0 \
    --set island.r icon.padding_left=0 icon.width=0 label.padding_left=0 label.width=0 label.padding_right=0
  sleep 0.25
  # hide only if nothing opened it again in the meantime
  if [ ! -s "$CHWILA" ] && [ -z "$(pomo_zostalo)" ]; then
    sb --set island.l drawing=off --set island.r drawing=off
  fi
}

# seconds left of the pomodoro (empty if none is running)
pomo_zostalo() {
  [ -f "$POMO" ] || return
  read -r start koniec < "$POMO"
  echo $(( koniec - $(date +%s) ))
}

pomo_tekst() {
  read -r start koniec < "$POMO"
  zost=$(( koniec - $(date +%s) ))
  [ $zost -lt 0 ] && zost=0
  calosc=$(( koniec - start ))
  # circle slice: how many eighths have passed
  i=$(( (calosc - zost) * 8 / calosc ))
  [ $i -gt 7 ] && i=7
  IKONA="${PLASTRY[$i]}"
  CZAS=$(printf "%02d:%02d" $((zost / 60)) $((zost % 60)))
}

pokaz_pomodoro() {
  pomo_tekst
  otworz "$IKONA" $BLUE "focus" $GREY "$F_ZWYKLY" "$CZAS" $FG
}

# after a short popup: back to the pomodoro, or the island hides
wroc() {
  if [ -n "$(pomo_zostalo)" ]; then
    pokaz_pomodoro
  else
    zamknij
  fi
}

# $1 how many seconds, the rest like in otworz
na_chwile() {
  czas=$1
  shift
  otworz "$@"
  echo $$ > "$CHWILA"
  (
    sleep $czas
    if [ "$(cat "$CHWILA" 2>/dev/null)" = "$$" ]; then
      : > "$CHWILA"
      wroc
    fi
  ) > /dev/null 2>&1 &
  disown
}

echo "--- $SENDER $INFO $CMD $CODE" >> "$LOG"

case "$SENDER" in
  volume_change)
    VOL="$INFO"
    case "$VOL" in
      [6-9][0-9]|100) IK="󰕾" ;;
      [3-5][0-9]) IK="󰖀" ;;
      [1-9]|[1-2][0-9]) IK="󰕿" ;;
      *) IK="󰖁" ;;
    esac
    na_chwile 2 "$IK" $GREY "$VOL%" $FG "$F_GRUBY" "%$VOL" $FG2
    ;;

  brightness_change)
    # $INFO is either 0.0-1.0 or already a percentage
    JASN=$(awk -v j="$INFO" 'BEGIN { if (j <= 1) j = j * 100; printf "%d", j + 0.5 }')
    na_chwile 2 "󰃟" $GREY "$JASN%" $FG "$F_GRUBY" "%$JASN" $FG2
    ;;

  power_source_change)
    PROC=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
    if [ "$INFO" = "AC" ]; then
      ZOST=$(pmset -g batt | grep -Eo "\d+:\d+ remaining" | cut -d' ' -f1)
      TXT="$PROC%"
      [ -n "$ZOST" ] && [ "$ZOST" != "0:00" ] && TXT="$PROC%  $ZOST"
      na_chwile 4 "󰂄" $GREEN "charging" $GREY "$F_ZWYKLY" "$TXT" $FG
    else
      na_chwile 3 "󰁹" $GREY "battery" $GREY "$F_ZWYKLY" "$PROC%" $FG
    fi
    ;;

  island_cmd)
    # CMD, CODE come from the zsh hook
    na_chwile 5 "󰅙" $RED "$CMD" $FG "$F_GRUBY" "exit $CODE" $RED
    ;;

  island_media)
    # TITLE, ARTIST from plugins/island_media.sh, cut to fit the island
    TITLE=$(perl -CSA -e '$t = $ARGV[0]; $t = substr($t, 0, 19) . "…" if length($t) > 20; print $t' "$TITLE")
    ARTIST=$(perl -CSA -e '$t = $ARGV[0]; $t = substr($t, 0, 15) . "…" if length($t) > 16; print $t' "$ARTIST")
    na_chwile 5 "󰝚" $BLUE "$ARTIST" $GREY "$F_ZWYKLY" "$TITLE" $FG
    ;;

  island_pomodoro)
    # start or stop from scripts/pomodoro
    if [ -n "$(pomo_zostalo)" ]; then
      sb --set island update_freq=1
      : > "$CHWILA"
      pokaz_pomodoro
    else
      sb --set island update_freq=0
      [ -s "$CHWILA" ] || zamknij
    fi
    ;;

  routine|forced)
    zost=$(pomo_zostalo)
    [ -z "$zost" ] && exit 0
    if [ "$zost" -le 0 ]; then
      rm -f "$POMO"
      sb --set island update_freq=0
      afplay /System/Library/Sounds/Glass.aiff &
      na_chwile 6 "󰄬" $GREEN "pomodoro" $GREY "$F_ZWYKLY" "done" $GREEN
    elif [ ! -s "$CHWILA" ]; then
      pomo_tekst
      if [ "$SENDER" = "forced" ]; then
        sb --set island update_freq=1
        pokaz_pomodoro
      else
        # every second only the text, no animation
        sb --set island.l icon="$IKONA" --set island.r label="$CZAS"
      fi
    fi
    ;;
esac
