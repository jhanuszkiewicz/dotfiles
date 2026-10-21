// wypisuje aktywne okno: "x y szer wys skala gora lewo" (w punktach, skala = 2 na retinie)
// gora/lewo = ile zajmuje pasek menu / dock, bo ghostty liczy pozycje od widocznej czesci ekranu
// bez System Events - czyta liste okien z CoreGraphics, wiec jest szybkie i nie potrzebuje uprawnien
ObjC.import('AppKit')
ObjC.import('CoreGraphics')

function run() {
  var ekran = $.NSScreen.mainScreen
  var scale = ekran.backingScaleFactor
  var f = ekran.frame
  var v = ekran.visibleFrame
  var gora = f.size.height - (v.origin.y + v.size.height)
  var lewo = v.origin.x - f.origin.x

  var pid = $.NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier

  // 1 = tylko widoczne okna, 16 = bez pulpitu; lista jest od przodu do tylu
  var okna = ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(1 | 16, 0)))

  var wynik = [0, 0, f.size.width, f.size.height]
  for (var i = 0; i < okna.length; i++) {
    var o = okna[i]
    if (o.kCGWindowOwnerPID == pid && o.kCGWindowLayer == 0) {
      var b = o.kCGWindowBounds
      wynik = [b.X, b.Y, b.Width, b.Height]
      break
    }
  }
  // aktywna apka bez okna - zostaje caly ekran

  return wynik.concat([scale, gora, lewo]).map(Math.round).join(' ')
}
