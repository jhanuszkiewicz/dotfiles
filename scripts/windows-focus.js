// used by scripts/windows: windows-focus.js APP INDEX
// brings that window up (restores it first when minimized)
function run(argv) {
  var se = Application('System Events')
  var p = se.processes.byName(argv[0])
  var w = p.windows[parseInt(argv[1]) - 1]
  try {
    var m = w.attributes.byName('AXMinimized')
    if (m.value()) m.value = false
  } catch (e) {}
  w.actions.byName('AXRaise').perform()
  p.frontmost = true
}
