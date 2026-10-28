// what's playing, from media-control (same as the notch island in the bar)
// nothing playing = nothing shown
export const command = "/opt/homebrew/bin/media-control get 2>/dev/null"
export const refreshFrequency = 3000

export const className = `
  opacity: var(--vis, 1);
  transition: opacity 0.4s ease;
  bottom: 9%;
  left: 6%;
  font-family: var(--font), monospace;
  font-size: var(--fs);
  color: var(--fg);
  text-shadow: 0 2px 12px rgba(0, 0, 0, 0.5);

  .state {
    color: var(--accent);
  }
  .artist {
    color: var(--dim);
  }
`

export const render = ({ output }) => {
  let d = null
  try {
    d = JSON.parse(output)
  } catch (e) {
    return null
  }
  if (!d || !d.title) {
    return null
  }
  return (
    <div>
      <div className="state">{d.playing ? "▶ playing" : "⏸ paused"}</div>
      <div>{d.title}</div>
      <div className="artist">{d.artist}</div>
    </div>
  )
}
