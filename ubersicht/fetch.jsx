// small fetch on the dark trees on the left
// the swatches are the 16 terminal colors of the active preset
export const command = `
k="$HOME/.dotfiles/kitty/kitty.conf"
boot=$(sysctl -n kern.boottime | awk -F'[ ,]+' '{print $4}')
s=$(( $(date +%s) - boot ))
font=$(grep -m1 '^font_family' "$k" | sed -E 's/^font_family +//; s/.*family="([^"]*)".*/\\1/')
echo "$(whoami)@$(scutil --get LocalHostName)"
echo "os|macOS $(sw_vers -productVersion)"
echo "wm|paneru"
echo "term|kitty + tmux"
echo "font|$font"
echo "preset|$(cat "$HOME/.dotfiles/presets/.active")"
echo "uptime|$((s / 86400))d $((s % 86400 / 3600))h $((s % 3600 / 60))m"
`
export const refreshFrequency = 30000

export const className = `
  opacity: var(--vis, 1);
  transition: opacity 0.4s ease;
  top: 34%;
  left: 6%;
  font-family: var(--font), monospace;
  font-size: var(--fs);
  line-height: 1.5;
  color: var(--fg);
  text-shadow: 0 2px 12px rgba(0, 0, 0, 0.5);

  .host {
    color: var(--host);
  }
  .line {
    color: var(--c8);
  }
  .key {
    display: inline-block;
    width: 8ch;
    color: var(--accent);
  }
  .swatches {
    display: grid;
    grid-template-columns: repeat(8, 2ch);
    margin-top: 14px;
  }
  .sw {
    height: 1.3em;
  }
`

export const render = ({ output }) => {
  const lines = (output || "").trim().split("\n")
  const host = lines[0] || ""

  const rows = []
  for (let i = 1; i < lines.length; i++) {
    const [key, val] = lines[i].split("|")
    rows.push(<div key={key}><span className="key">{key}</span>{val}</div>)
  }

  const sw = []
  for (let i = 0; i < 16; i++) {
    sw.push(<span key={i} className="sw" style={{ background: `var(--c${i})` }} />)
  }

  return (
    <div>
      <div className="host">{host}</div>
      <div className="line">{"-".repeat(host.length)}</div>
      {rows}
      <div className="swatches">{sw}</div>
    </div>
  )
}
