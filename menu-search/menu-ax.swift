// menu-ax - reads and clicks the menu bar of a macos app through the accessibility api
//   menu-ax front              -> "<pid>\t<name>" of the frontmost app
//   menu-ax list <pid>         -> every clickable menu item, one per line:
//                                 "<path padded + shortcut>\t<path>"   (path = File › Export…)
//   menu-ax press <pid> <path> -> brings the app to the front and clicks that item
//   menu-ax bar                -> "<pid>\t<name>" of the frontmost app, then its menus
//                                 as "<index>\t<title>" (for the sketchybar menu segment)
//   menu-ax open <pid> <index> -> drops down that menu of the macos menu bar
//   menu-ax dump <pid> <dir>   -> every menu into <dir>/1, <dir>/2 ... (same rows as items)
//   menu-ax items <pid> <path> -> one menu (path = "Edit" or "Format › Font") for the
//                                 bar's own dropdown, one row per line:
//                                 "<kind>\t<mark>\t<shown>\t<path>"
// needs accessibility permission for the app it runs from
// (kitty for the menu search, sketchybar for the bar)
//
// build: swiftc -O menu-ax.swift -o menu-ax

import Cocoa
import ApplicationServices

let SEP = " › "

func get(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?
    if AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success {
        return v
    }
    return nil
}

func kids(_ el: AXUIElement) -> [AXUIElement] {
    if let k = get(el, "AXChildren") as? [AXUIElement] {
        return k
    }
    return []
}

func title(_ el: AXUIElement) -> String {
    if let t = get(el, "AXTitle") as? String {
        return t
    }
    return ""
}

// the menu hanging under an item (menu bar item or item with a submenu), nil = plain item
func submenu(_ el: AXUIElement) -> AXUIElement? {
    for k in kids(el) {
        if (get(k, "AXRole") as? String) == "AXMenu" {
            return k
        }
    }
    return nil
}

// ⌃⌥⇧⌘ + key, empty when the item has no shortcut
func shortcut(_ el: AXUIElement) -> String {
    guard let ch = get(el, "AXMenuItemCmdChar") as? String, !ch.isEmpty else {
        return ""
    }
    var mods = 0
    if let m = get(el, "AXMenuItemCmdModifiers") as? Int {
        mods = m
    }
    var s = ""
    if mods & 4 != 0 { s += "⌃" }
    if mods & 2 != 0 { s += "⌥" }
    if mods & 1 != 0 { s += "⇧" }
    if mods & 8 == 0 { s += "⌘" }
    return s + ch.uppercased()
}

// the same shortcut written with words: "shift+cmd+o". the bar font (Departure Mono)
// has no ⌘⌥⇧⌃, macos squeezed them in from another font and they came out blurry
func shortcutWords(_ ch: String, _ mods: Int) -> String {
    if ch.isEmpty {
        return ""
    }
    var s = ""
    if mods & 4 != 0 { s += "ctrl+" }
    if mods & 2 != 0 { s += "opt+" }
    if mods & 1 != 0 { s += "shift+" }
    if mods & 8 == 0 { s += "cmd+" }
    var key = ch.lowercased()
    if key == " " {
        key = "space"
    }
    return s + key
}

// several attributes of one element in a single call. every call is a round trip
// to the app, and a menu row needs 6 of them - one by one that's what made the
// dropdown slow in slow apps (electron ones especially)
func getMany(_ el: AXUIElement, _ names: [String]) -> [AnyObject?] {
    var out: [AnyObject?] = Array(repeating: nil, count: names.count)
    var vals: CFArray? = nil
    let r = AXUIElementCopyMultipleAttributeValues(el, names as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &vals)
    guard r == .success, let cf = vals else {
        return out
    }
    let arr = cf as NSArray as [AnyObject]
    for i in 0..<min(arr.count, names.count) {
        let v = arr[i]
        // a missing attribute comes back as an AXValue holding an error
        if CFGetTypeID(v) == AXValueGetTypeID() && AXValueGetType(v as! AXValue) == .axError {
            continue
        }
        out[i] = v
    }
    return out
}

func menuBar(_ pid: pid_t) -> AXUIElement? {
    let app = AXUIElementCreateApplication(pid)
    guard let mb = get(app, "AXMenuBar") else {
        return nil
    }
    return (mb as! AXUIElement)
}

var listRows: [(String, String)] = []

func walk(_ menu: AXUIElement, _ path: String) {
    for it in kids(menu) {
        let t = title(it)
        // separators have no title
        if t.isEmpty {
            continue
        }
        let p = path + SEP + t
        if let sub = submenu(it) {
            walk(sub, p)
            continue
        }
        if (get(it, "AXEnabled") as? Bool) == false {
            continue
        }
        listRows.append((p, shortcut(it)))
    }
}

func list(_ pid: pid_t) {
    guard let mb = menuBar(pid) else {
        fputs("this app has no menu bar\n", stderr)
        exit(1)
    }
    let bars = kids(mb)
    for i in 0..<bars.count {
        // 0 = the apple menu, nothing useful there
        if i == 0 {
            continue
        }
        if let m = submenu(bars[i]) {
            walk(m, title(bars[i]))
        }
    }

    // shortcuts in one column, dimmed
    var width = 0
    for (p, _) in listRows {
        width = max(width, p.count)
    }
    width = min(width, 56)
    for (p, sc) in listRows {
        var shown = p
        if p.count < width {
            shown += String(repeating: " ", count: width - p.count)
        }
        if !sc.isEmpty {
            shown += "   \u{1b}[2m" + sc + "\u{1b}[0m"
        }
        print(shown + "\t" + p)
    }
}

func press(_ pid: pid_t, _ path: String) {
    // app back to the front first, menu commands act on its focused window
    let app = AXUIElementCreateApplication(pid)
    let front = AXUIElementSetAttributeValue(app, "AXFrontmost" as CFString, kCFBooleanTrue)
    if front != .success {
        fputs("couldn't bring the app to the front (AXError \(front.rawValue))\n", stderr)
    }
    usleep(150000)

    guard let mb = menuBar(pid) else {
        fputs("this app has no menu bar\n", stderr)
        exit(1)
    }
    // walk down by titles: menu bar item, then the items inside
    let parts = path.components(separatedBy: SEP)
    var level = kids(mb)
    for n in 0..<parts.count {
        var found: AXUIElement? = nil
        for k in level {
            if title(k) == parts[n] {
                found = k
                break
            }
        }
        guard let f = found else {
            fputs("not found: \(parts[n])\n", stderr)
            exit(1)
        }
        if n == parts.count - 1 {
            let r = AXUIElementPerformAction(f, "AXPress" as CFString)
            if r != .success {
                fputs("click failed (AXError \(r.rawValue)) on: \(path)\n", stderr)
                exit(1)
            }
            exit(0)
        }
        guard let sub = submenu(f) else {
            fputs("no submenu under: \(parts[n])\n", stderr)
            exit(1)
        }
        level = kids(sub)
    }
}

// width in points of a title in the bar font (Departure Mono 11), so the bar knows
// exactly how many menus fit before the notch
// the bar font, looked up once (looking it up for every row was slow)
var barFont: NSFont? = nil

func textWidth(_ s: String) -> Int {
    if barFont == nil {
        // by family first (that's how sketchybar asks for it), then by name
        var font: NSFont? = NSFontManager.shared.font(withFamily: "Departure Mono", traits: [], weight: 5, size: 11)
        for name in ["DepartureMono-Regular", "Departure Mono", "Departure Mono Regular"] {
            if font == nil {
                font = NSFont(name: name, size: 11)
            }
        }
        barFont = font ?? NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    }
    let w = (s as NSString).size(withAttributes: [.font: barFont!]).width
    return Int(w.rounded(.up))
}

// width of the part of the screen left of the notch (0 = no notch) and the screen width
func screenInfo() -> (Int, Int) {
    guard let scr = NSScreen.screens.first else {
        return (0, 0)
    }
    var left = 0
    if #available(macOS 12.0, *) {
        if let a = scr.auxiliaryTopLeftArea {
            left = Int(a.width)
        }
    }
    return (left, Int(scr.frame.width))
}

// for sketchybar: front app first (works without permission), then the menu titles.
// index 0 is the apple menu, so it's skipped. index 1 is the app menu (its title is the app name)
//   first line: "<pid>\t<name>\t<width left of the notch>\t<screen width>"
//   then:       "<index>\t<title>\t<title width in points>"
func bar() {
    guard let app = NSWorkspace.shared.frontmostApplication else {
        exit(1)
    }
    let pid = app.processIdentifier
    let (left, sw) = screenInfo()
    print("\(pid)\t\(app.localizedName ?? "?")\t\(left)\t\(sw)")
    if !AXIsProcessTrusted() {
        exit(2)
    }
    guard let mb = menuBar(pid) else {
        exit(0)
    }
    let bars = kids(mb)
    for i in 0..<bars.count {
        if i == 0 {
            continue
        }
        let t = title(bars[i])
        if t.isEmpty {
            continue
        }
        print("\(i)\t\(t)\t\(textWidth(t))")
    }
}

// the real macos menu drops down (at the spot where it would be in the macos menu bar)
func openMenu(_ pid: pid_t, _ idx: Int) {
    guard let mb = menuBar(pid) else {
        fputs("this app has no menu bar\n", stderr)
        exit(1)
    }
    let bars = kids(mb)
    if idx < 1 || idx >= bars.count {
        fputs("no menu number \(idx)\n", stderr)
        exit(1)
    }
    // closes a menu that's already open, otherwise the press sometimes does nothing
    AXUIElementPerformAction(bars[idx], "AXCancel" as CFString)
    usleep(100000)
    let r = AXUIElementPerformAction(bars[idx], "AXPress" as CFString)
    // some apps answer only after the menu closes - running out of time is fine then
    if r != .success && r != .cannotComplete {
        fputs("couldn't open the menu (AXError \(r.rawValue))\n", stderr)
        exit(1)
    }
}

// one menu for the bar's own dropdown (path = "Edit" or "Format › Font")
// first line "W\t<width of the widest row in points>", then one row per line:
//   kind: item / off (disabled) / sub (opens a submenu) / sep / up (back to the parent)
//   mark: 1 = has a checkmark
//   shown: title padded to one width + shortcut on the right, so every row has
//          the same length and the dropdown lines up (the bar font is mono)
// nil = no menu bar / menu not found
func menuLines(_ pid: pid_t, _ path: String) -> [String]? {
    guard let mb = menuBar(pid) else {
        return nil
    }
    let parts = path.components(separatedBy: SEP)
    var level = kids(mb)
    for p in parts {
        var found: AXUIElement? = nil
        for k in level {
            if title(k) == p {
                found = k
                break
            }
        }
        guard let f = found, let sub = submenu(f) else {
            return nil
        }
        level = kids(sub)
    }

    let names = ["AXTitle", "AXEnabled", "AXMenuItemCmdChar", "AXMenuItemCmdModifiers",
                 "AXMenuItemMarkChar", "AXChildren"]

    // kind, mark, title, right column, path
    var rows: [(String, String, String, String, String)] = []
    if parts.count > 1 {
        let up = parts.dropLast().joined(separator: SEP)
        rows.append(("up", "0", "‹ " + parts[parts.count - 2], "", up))
    }
    for it in level {
        let v = getMany(it, names)
        var t = (v[0] as? String) ?? ""
        t = t.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\t", with: " ")
        if t.isEmpty {
            // no separator at the top or two in a row
            if rows.isEmpty || rows[rows.count - 1].0 == "sep" || rows[rows.count - 1].0 == "up" {
                continue
            }
            rows.append(("sep", "0", "", "", ""))
            continue
        }
        let enabled = (v[1] as? Bool) ?? true
        let ch = (v[2] as? String) ?? ""
        let mods = (v[3] as? Int) ?? 0
        let markChar = (v[4] as? String) ?? ""
        let children = (v[5] as? [AXUIElement]) ?? []

        // a submenu = one of the children is an AXMenu (plain items have no children)
        var hasSub = false
        for k in children {
            if (get(k, "AXRole") as? String) == "AXMenu" {
                hasSub = true
                break
            }
        }

        let p = path + SEP + t
        let mark = markChar.isEmpty ? "0" : "1"
        if hasSub {
            rows.append(("sub", mark, t, "›", p))
        } else if !enabled {
            rows.append(("off", mark, t, shortcutWords(ch, mods), p))
        } else {
            rows.append(("item", mark, t, shortcutWords(ch, mods), p))
        }
    }
    if rows.count > 0 && rows[rows.count - 1].0 == "sep" {
        rows.removeLast()
    }

    // column widths, long titles get cut
    var w1 = 0
    var w2 = 0
    for r in rows {
        w1 = max(w1, min(r.2.count, 40))
        w2 = max(w2, r.3.count)
    }
    var lines: [String] = []
    var widest = 0
    for r in rows {
        var t = r.2
        if t.count > 40 {
            t = String(t.prefix(39)) + "…"
        }
        var shown = t + String(repeating: " ", count: w1 - t.count)
        if w2 > 0 {
            shown += "    " + String(repeating: " ", count: w2 - r.3.count) + r.3
        }
        widest = max(widest, textWidth(shown))
        lines.append("\(r.0)\t\(r.1)\t\(shown)\t\(r.4)")
    }
    return ["W\t\(widest)"] + lines
}

func items(_ pid: pid_t, _ path: String) {
    guard let lines = menuLines(pid, path) else {
        fputs("menu not found: \(path)\n", stderr)
        exit(1)
    }
    for l in lines {
        print(l)
    }
}

// every menu of the app at once, one file per menu: "<dir>/<n>", n = its place on the
// bar (same numbering as bar). menus.sh runs it in the background after an app switch,
// so a click can show the dropdown straight from the file
func dump(_ pid: pid_t, _ dir: String) {
    guard let mb = menuBar(pid) else {
        exit(1)
    }
    let bars = kids(mb)
    var n = 0
    for i in 0..<bars.count {
        if i == 0 {
            continue
        }
        let t = title(bars[i])
        if t.isEmpty {
            continue
        }
        n += 1
        if let lines = menuLines(pid, t) {
            let text = lines.joined(separator: "\n") + "\n"
            try? text.write(toFile: dir + "/" + String(n), atomically: true, encoding: .utf8)
        }
    }
}

// don't hang for 6 s when an app is busy, the bar waits for this
AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 1.0)

let args = CommandLine.arguments
if args.count < 2 {
    fputs("usage: menu-ax front | bar | list <pid> | press <pid> <path> | open <pid> <index> | items <pid> <path> | dump <pid> <dir>\n", stderr)
    exit(1)
}

if args[1] == "front" {
    guard let app = NSWorkspace.shared.frontmostApplication else {
        exit(1)
    }
    print("\(app.processIdentifier)\t\(app.localizedName ?? "?")")
    exit(0)
}

if args[1] == "bar" {
    bar()
    exit(0)
}

if !AXIsProcessTrusted() {
    fputs("no accessibility permission\n", stderr)
    fputs("add kitty (and sketchybar) in System Settings › Privacy & Security › Accessibility\n", stderr)
    exit(2)
}

if args[1] == "list" && args.count >= 3 {
    list(pid_t(Int32(args[2]) ?? 0))
} else if args[1] == "press" && args.count >= 4 {
    press(pid_t(Int32(args[2]) ?? 0), args[3])
} else if args[1] == "open" && args.count >= 4 {
    openMenu(pid_t(Int32(args[2]) ?? 0), Int(args[3]) ?? 0)
} else if args[1] == "items" && args.count >= 4 {
    items(pid_t(Int32(args[2]) ?? 0), args[3])
} else if args[1] == "dump" && args.count >= 4 {
    dump(pid_t(Int32(args[2]) ?? 0), args[3])
} else {
    fputs("usage: menu-ax front | bar | list <pid> | press <pid> <path> | open <pid> <index> | items <pid> <path> | dump <pid> <dir>\n", stderr)
    exit(1)
}
