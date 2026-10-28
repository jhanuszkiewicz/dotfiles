// not a visible widget - loads colors and font from theme.css as css variables,
// the other widgets use var(--fg) etc. hswi swaps theme.css with the preset
//
// also sets --vis (0/1): every widget fades with it, hidden while the active
// workspace has windows, so they don't show through the see-through terminal. window count comes from desk-cache
// (/tmp/paneru_desk_$USER), which also pokes ubersicht to refresh right away
export const command = `
cat "$HOME/.dotfiles/ubersicht/theme.css"
read -r ws idx cnt 2>/dev/null < "/tmp/paneru_desk_$USER"
if [ "\${cnt:-0}" -gt 0 ]; then
  echo ':root { --vis: 0; }'
else
  echo ':root { --vis: 1; }'
fi
`
export const refreshFrequency = 3000

export const className = "display: none;"

export const render = ({ output }) => <style>{output}</style>
