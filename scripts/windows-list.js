// used by scripts/windows: one line per window of every open app
// app <tab> index <tab> [min] <tab> title
function run() {
  var se = Application('System Events')
  var procs = se.processes.whose({ backgroundOnly: false })()
  var out = []
  for (var i = 0; i < procs.length; i++) {
    var p = procs[i]
    var name = p.name()
    var okna
    try { okna = p.windows() } catch (e) { continue }
    for (var j = 0; j < okna.length; j++) {
      var w = okna[j]
      var t = ''
      try { t = w.name() || '' } catch (e) {}
      // skip the popups (launcher, keys, ctl, btop, menu and this list)
      if (name == 'kitty' && /^(launcher|keys|ctl|btop|windows|menu)$/.test(t)) continue
      var m = false
      try { m = w.attributes.byName('AXMinimized').value() } catch (e) {}
      out.push([name, j + 1, m ? '[min]' : '', t].join('\t'))
    }
  }
  return out.join('\n')
}
