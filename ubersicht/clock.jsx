// big clock in the empty sky, date + weather under it
// weather from wttr.in, cached for 15 min so it doesn't hit the network every 5 s
export const command = `
w=/tmp/ubersicht_weather_$USER
if [ -z "$(find "$w" -mmin -15 2>/dev/null)" ]; then
  ( curl -s --max-time 5 'https://wttr.in/Poznan?format=%C+%t' > "$w.tmp" &&
    grep -q '°' "$w.tmp" && mv "$w.tmp" "$w" ) >/dev/null 2>&1 &
fi
date '+%H:%M'
LC_ALL=C date '+%a %d.%m' | tr '[:upper:]' '[:lower:]'
awk '{t = $NF; $NF = ""; print tolower($0) t}' "$w" 2>/dev/null
`
export const refreshFrequency = 5000

export const className = `
  opacity: var(--vis, 1);
  transition: opacity 0.4s ease;
  top: 14%;
  left: 50%;
  transform: translateX(-50%);
  text-align: center;
  font-family: var(--font), monospace;
  color: var(--fg);
  text-shadow: 0 2px 16px rgba(0, 0, 0, 0.35);

  .time {
    font-size: var(--fs-big);
    line-height: 1;
  }
  .sub {
    font-size: var(--fs);
    color: var(--dim);
    margin-top: 12px;
  }
`

export const render = ({ output }) => {
  const lines = (output || "").trim().split("\n")
  let sub = lines[1] || ""
  if (lines[2]) {
    sub = sub + "  ·  " + lines[2]
  }
  return (
    <div>
      <div className="time">{lines[0]}</div>
      <div className="sub">{sub}</div>
    </div>
  )
}
