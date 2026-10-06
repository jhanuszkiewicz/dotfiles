# Terminal & Desktop Setup — Design Proposal

| | |
|---|---|
| **Date** | 2026-10-05 |
| **Status** | Proposal for review. No config file has been changed yet. |
| **Scope** | Everything in `~/.dotfiles`, plus the macOS settings it depends on |
| **Machine** | MacBook Pro 14" (M5, notch) · macOS 26.3.1 Tahoe · keyboard layout *Polish Pro* |

Every config snippet below was checked against the versions installed on this Mac. Section 11 says how.

**Contents:** 1 TL;DR · 2 Goals · 3 Audit · 4 Design system · 5 Component plans · 6 Neovim plugin plan · 7 What is missing · 8 Repo layout & install · 9 Roadmap · 10 Decisions to confirm · 11 Verification & references

---

## 1. TL;DR

- **One palette: Tokyo Night *Night*.** Three different "Tokyo Nights" are mixed today: Storm in Ghostty and btop, Night in bat, fzf and SketchyBar, and the starship preset uses its own colours. Every theme file will come from one place, the [`extras/`](https://github.com/folke/tokyonight.nvim/tree/main/extras) of `folke/tokyonight.nvim`. That folder is generated from the same palette as the Neovim theme.
- **One font, one spacing grid.** JetBrainsMono Nerd Font (already installed) and 8 px between the screen edge, the bar and the windows. Today the gap under the bar is 12 px.
- **One translucency.** Ghostty at 0.92 with blur, plus `background-opacity-cells = true`, so Neovim, btop and lazygit are translucent too. Without that option they render opaque.
- **One set of keys.**
  - Caps Lock: tap = Esc, hold = window-manager key.
  - Left ⌥ = Alt in the terminal; right ⌥ = Polish letters.
  - `hjkl` in every tool.
- **One tool per job, in the shell and in Neovim:**
  - fzf ↔ fzf-lua;
  - yazi ↔ yazi.nvim;
  - lazygit, with delta rendering diffs;
  - the bat theme is reused by delta and by fzf previews.
- **Neovim from scratch on the built-in `vim.pack`** (Neovim 0.12.5; kickstart.nvim has switched to it as well), built in four small phases.
- **Missing:** zsh plugins, git-delta, yazi, Karabiner-Elements, sketchybar-app-font, a Brewfile, a tracked git config and a `macos.sh`.
- **Remove:** `lsd`, which duplicates eza.

## 2. Goals and non-goals

**Goals**
- *Consistent look:* colours, font, spacing, corner radii and translucency.
- *Consistent interaction:* the same navigation keys, and the same fuzzy finder, file manager and git UI inside and outside Neovim.
- *Reproducible:* a fresh Mac gets the whole setup from `Brewfile` + `install.sh` + `macos.sh`.
- *Fast:* a new shell starts in under 100 ms (today 230–300 ms).

**Non-goals (YAGNI)**
- Automatic light/dark switching. You run Dark mode.
- A generator that templates every config from one palette file. The extras files plus one `theme/colors.sh` are enough.
- Replacing yabai. It works: SIP is partially disabled, the scripting addition loads, and the sudoers hash matches the binary.

## 3. Audit: what is there today

| Component | Version | State | Notes |
|---|---|---|---|
| Ghostty | 1.3.1 | configured | **TokyoNight Storm**, duplicated keys |
| zsh | system | minimal | no plugins, no `compinit`, no history settings |
| starship | 1.26.0 | Tokyo Night preset | the preset's own colours; modules for PHP/Go/Rust/Bun, none for C/C++, Python or Lua |
| Neovim | 0.12.5 | **empty `init.lua`** | leftovers from earlier experiments (issue 9) |
| yabai | 7.1.25 | running, scripting addition loaded | bsp, gap 8, 2 rules |
| skhd | 0.3.9 | running | ⌃⌥ scheme, spaces 1–4 |
| JankyBorders | 1.9.0 | running | blue / grey, width 5 |
| SketchyBar | 2.24.0 | running | bash, Night colours, no app icons |
| btop | 1.4.7 | themed | **tokyo-storm**, through an absolute Cellar path |
| bat | 0.26.1 | themed | `tokyonight_night` (theme cache built) |
| eza, fzf, zoxide, fd, rg | current | in use | fzf in Night colours; eza has no theme |
| lazygit 0.66, tmux, fastfetch, gh, stow | installed | not configured | lazygit reads `~/Library/Application Support/lazygit` |

### Issues found

1. **Three Tokyo Night variants at once.** Storm (`#24283b`) is in Ghostty and btop. Night (`#1a1b26`) is in bat, fzf and SketchyBar. The starship preset has private colours (`#769ff0`, `#394260`, …) that belong to neither.
2. **Ghostty config.**
   - `window-padding-*` and `background-opacity` are set twice; the last value wins.
   - The comment above `window-decoration` says it hides the macOS menu bar. It does not.
   - `background-blur-radius` is the old name of `background-blur`.
   - Ghostty does not support inline comments: `font-size = 14 # big` is an invalid value.
3. **Translucency will be inconsistent.** Ghostty applies `background-opacity` only to cells with no explicit background colour. Neovim, lazygit and btop (`theme_background = true`) therefore paint opaque blocks on a translucent terminal.
4. **btop.**
   - `color_theme` points into `/opt/homebrew/Cellar/btop/1.4.7/…`, so it breaks on the next `brew upgrade`.
   - `save_config_on_exit = true` rewrites the tracked file, which is probably how the absolute path got there.
   - `vim_keys = false`.
5. **Spacing.** The bar ends at y = 36 (`y_offset 4` + `height 32`), and windows start at y = 48 (`external_bar 40` + `top_padding 8`). That leaves 12 px under the bar and 8 px everywhere else.
6. **skhd and spaces.**
   - You have 5 spaces; SketchyBar creates 9 items; skhd binds 1–4.
   - Spaces 2–3 use the `float` layout only as runtime state, which a yabai restart forgets.
   - `open -na Ghostty` starts a **new Ghostty process** on every key press.
7. **macOS.** *Displays have separate Spaces* is **off** (`spans-displays = 1`). yabai requires it to be on, and misbehaves as soon as an external display is connected.
8. **zsh startup.** `conda shell.zsh hook` alone takes about 0.22 s of the 0.23–0.30 s startup.
9. **Neovim leftovers.**
   - `~/.local/share/nvim` holds about 790 MB from earlier experiments: `lazy/` 122 MB, `mason/` 567 MB, and `site/` 102 MB including 21 kickstart plugins installed on 17 Sep.
   - An untracked `nvim/nvim-pack-lock.json`, written at 23:08 today, lists those old plugins.
   - `~/.local/state/nvim/lsp.log` is 114 MB.
10. **Reproducibility.**
    - There is no Brewfile.
    - `install.sh` handles neither `.zprofile`, git, eza, lazygit, yazi nor Karabiner, and does not run `bat cache --build`.
    - Both `lsd` and `eza` are installed.

## 4. Design system

### 4.1 Palette: Tokyo Night "Night"

Why Night:
- You already chose Tokyo Night.
- bat, fzf and SketchyBar already use Night.
- It is the darkest variant, so it keeps the best contrast under 0.92 opacity and blur.

If you prefer the lighter Storm, switch *every* file to Storm. Just never mix the two.

| Role | folke name | Hex | Where |
|---|---|---|---|
| Background | `bg` | `#1a1b26` | terminal, Neovim, bar (90 % alpha) |
| Background, darker | `bg_dark` | `#16161e` | floats, sidebars, fzf, prompt time pill |
| Surface | `bg_highlight` | `#292e42` | active space pill, cursor line, prompt language pill |
| Border / gutter | `fg_gutter` | `#3b4261` | inactive window border, prompt git pill |
| Muted | `comment` | `#565f89` | inactive space numbers, autosuggestions |
| Text | `fg` | `#c0caf5` | main text, bar labels |
| Text, dim | `fg_dark` | `#a9b1d6` | secondary text, prompt OS pill |
| **Primary accent** | `blue` | `#7aa2f7` | focus: active border, active space, prompt directory, Neovim NORMAL |
| Secondary accent | `magenta` | `#bb9af7` | front-app name, end of the border gradient, Neovim VISUAL |
| Info | `cyan` | `#7dcfff` | links, matches |
| Success | `green` | `#9ece6a` | prompt `❯`, battery |
| Warning | `yellow` | `#e0af68` | slow-command duration, warnings |
| Error | `red` | `#f7768e` | prompt `❯` after an error, diagnostics |

Three rules:

1. **ANSI first.** Tools that only use the 16 ANSI colours inherit the Ghostty theme automatically: zsh syntax highlighting, `ls`, git and most CLIs. Only true-colour tools need theme files.
2. **One source of theme files:** `folke/tokyonight.nvim/extras/<tool>/tokyonight_night.*`. It comes from the same generator as the Neovim colourscheme.
   - It is available for Ghostty, btop, delta, eza, fzf, lazygit, yazi, tmux and Sublime. bat uses the Sublime file, which you already have.
   - Ghostty's built-in "TokyoNight Night" differs from folke's file in 6 bright ANSI colours and in the cursor text colour, so use folke's file.
3. **One `theme/colors.sh`** for the tools configured from shell scripts (SketchyBar, JankyBorders, yabai):

```bash
# theme/colors.sh — Tokyo Night (night) as 0xAARRGGBB
export TN_BG=0xff1a1b26 TN_BG_DARK=0xff16161e TN_BG_HL=0xff292e42 TN_GUTTER=0xff3b4261
export TN_COMMENT=0xff565f89 TN_FG=0xffc0caf5 TN_FG_DARK=0xffa9b1d6
export TN_BLUE=0xff7aa2f7 TN_MAGENTA=0xffbb9af7 TN_CYAN=0xff7dcfff
export TN_GREEN=0xff9ece6a TN_YELLOW=0xffe0af68 TN_RED=0xfff7768e
export TN_BAR_BG=0xe61a1b26   # bg at 90 % alpha
```

### 4.2 Fonts

| Where | Font | Notes |
|---|---|---|
| Ghostty, VS Code | JetBrainsMono Nerd Font, 14 pt | already installed (cask) |
| SketchyBar text and glyphs | JetBrainsMono Nerd Font Bold | keeps the bar looking like the terminal |
| SketchyBar app icons | `sketchybar-app-font` | `brew install --cask font-sketchybar-app-font` |

### 4.3 Spacing: an 8 px grid

| Token | Value | Where |
|---|---|---|
| gap | 8 | yabai `window_gap` and `*_padding`; SketchyBar `margin` |
| bar | `y_offset=8`, `height=32` | SketchyBar (today `y_offset=4`) |
| reserved top | 40 = 8 + 32 | yabai `external_bar all:40:0` (unchanged) |
| inner padding | 12 | Ghostty `window-padding-x/y` |
| border | 5, round | JankyBorders (unchanged) |
| radii | bar 10, pills inside 6 | concentric corners: inner radius ≈ outer radius − padding |

The result is 8 px between the screen edge, the bar and every window.

### 4.4 Translucency

| Layer | Setting |
|---|---|
| Ghostty | `background-opacity = 0.92`, `background-blur = 20`, `background-opacity-cells = true` |
| SketchyBar | `color=$TN_BAR_BG` (90 %), `blur_radius=20` (unchanged) |
| Neovim | opaque colourscheme (`transparent = false`); Ghostty makes it translucent |
| btop | `theme_background = false` |

On macOS 26 you can also try `background-blur = macos-glass-regular`, the native Liquid Glass material, which Ghostty 1.3.1 accepts. It looks more like the system and less neutral, so compare both.

### 4.5 Keys

| Key | Role |
|---|---|
| Caps Lock, tap | Esc |
| Caps Lock, hold = ⌃⌥ ("WM") | window manager (skhd → yabai), global Ghostty actions |
| ⌘ | application level: Ghostty tabs and splits, macOS shortcuts |
| left ⌥ | Alt/Meta in the terminal: zsh word jumps, fzf `Alt-C`, Neovim `<M-…>` |
| right ⌥ | Polish letters ą ć ę ł ń ó ś ź ż |
| ⌃ | terminal and Neovim, e.g. `Ctrl-h/j/k/l` between Neovim splits |
| Space | Neovim leader |

Rule: **never bind a bare `alt`/`lalt` + letter in skhd.** On Polish Pro, ⌥L is ł and ⌥A is ą, and skhd would swallow them.

`hjkl` works everywhere:
- yabai: WM + `hjkl` focuses, WM + ⇧ + `hjkl` swaps (your current bindings).
- Neovim.
- btop, with `vim_keys`.
- lazygit and yazi, vim-style by default.
- fzf: `Ctrl-j/k`.
- `man` and the bat pager: `less` keys.

One tool per job:

| Job | Shell | Neovim | Shared |
|---|---|---|---|
| Fuzzy finding | fzf: `Ctrl-T`, `Ctrl-R`, `Alt-C`, fzf-tab | fzf-lua | the same fzf binary, colours and keys |
| Files | yazi (`y`) | yazi.nvim | the same program and theme |
| Git | lazygit (`lg`) | lazygit in a float, plus gitsigns | delta renders every diff |
| Syntax colours | bat | tokyonight.nvim | delta and fzf previews reuse the bat theme |

## 5. Component plans

### 5.1 Ghostty

This was checked with `ghostty +validate-config` on 1.3.1, with folke's theme file at `ghostty/themes/tokyonight_night`. Comments must be on their own lines.

```ini
# --- Look --------------------------------------------------------------------
# theme file: ghostty/themes/tokyonight_night (folke extras)
theme = tokyonight_night
font-family = JetBrainsMono Nerd Font
font-size = 14
adjust-cell-height = 10%

# --- Window ------------------------------------------------------------------
macos-titlebar-style = hidden
window-padding-x = 12
window-padding-y = 12
window-padding-balance = true
background-opacity = 0.92
# make Neovim / btop / lazygit backgrounds translucent as well
background-opacity-cells = true
# alternative on macOS 26: background-blur = macos-glass-regular
background-blur = 20
# borders + gaps already frame the windows
macos-window-shadow = false
window-save-state = always

# --- Input -------------------------------------------------------------------
# left Option = Alt (zsh, fzf, Neovim), right Option = Polish letters
macos-option-as-alt = left
mouse-hide-while-typing = true
copy-on-select = clipboard
shell-integration-features = sudo,ssh-env,ssh-terminfo

# --- Quick terminal: Caps + G (global keys need the Accessibility permission) --
keybind = global:ctrl+alt+g=toggle_quick_terminal
quick-terminal-position = top
quick-terminal-animation-duration = 0.15

# --- Optional: app icon in the palette (experimental in 1.3) -----------------
macos-icon = custom-style
macos-icon-frame = chrome
macos-icon-ghost-color = #c0caf5
macos-icon-screen-color = #1a1b26,#7aa2f7
```

### 5.2 zsh

- Keep the single `zsh/.zshrc`.
- Move `~/.zprofile`, which contains `brew shellenv`, into the repo as `zsh/.zprofile`.
- Install the plugins with Homebrew and skip a plugin manager. Four plugins don't justify one, and `brew upgrade` keeps them current.
- Load order matters: `compinit` → fzf-tab → widgets → syntax highlighting.
- Load conda lazily. This saves about 220 ms per new shell. The `base` environment then activates on the first `conda` call instead of at shell start.

Here is the proposed `.zshrc`. It passes `zsh -n`, and the plugin paths come from the Homebrew caveats.

```zsh
# ~/.zshrc — managed in ~/.dotfiles/zsh
HB="${HOMEBREW_PREFIX:-/opt/homebrew}"

# --- Environment ------------------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"   # lazygit & co. then read ~/.config on macOS
export EDITOR=nvim VISUAL=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
typeset -U path
path=("$HOME/.local/bin" "$HOME/.antigravity-ide/antigravity-ide/bin" $path)

# --- Theme: Tokyo Night (night) ---------------------------------------------
(( $+commands[vivid] )) && export LS_COLORS="$(vivid generate tokyonight-night)"
source "$HOME/.dotfiles/theme/fzf.sh"         # folke extras -> FZF_DEFAULT_OPTS
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'   # palette "comment"

# --- History & options -------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt auto_cd interactive_comments

# --- Completion (LS_COLORS must already be set) ------------------------------
FPATH="$HB/share/zsh-completions:$FPATH"
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no                   # fzf-tab draws the menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'

# --- fzf ----------------------------------------------------------------------
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"

# --- Plugins (order matters) --------------------------------------------------
source "$HB/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"   # after compinit, before widget wrappers
source <(fzf --zsh)
source "$HB/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HB/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"                          # zoxide wants to be initialised last

# --- Conda: initialise on first use (saves ~220 ms per new shell) -------------
conda() {
  unfunction conda
  eval "$("$HB/Caskroom/miniconda/base/bin/conda" shell.zsh hook)"
  conda "$@"
}

# --- Aliases & functions -------------------------------------------------------
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -la --icons=auto --git --group-directories-first'
alias lt='eza --tree --level=2 --icons=auto'
alias v='nvim'
alias lg='lazygit'
alias nvim-old='NVIM_APPNAME=nvim-lazy-config nvim'   # the LazyVim backup

function y() {                                     # yazi: cd into the last dir on exit
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}
```

Notes:
- If `compinit` warns about insecure directories, run `chmod go-w "$(brew --prefix)/share"` and `chmod -R go-w "$(brew --prefix)/share/zsh"`. This fix comes from the Homebrew caveat.
- If you later want vi mode in zsh (`zsh-vi-mode`), add `no-cursor` to Ghostty's `shell-integration-features`, so the plugin can control the cursor shape.

### 5.3 Starship

Keep the preset's look: the pills and the rounded separators. Replace its hard-coded colours with a named palette, and show the languages you actually use. This was checked with starship 1.26 (`starship prompt`, `starship explain`).

| Preset colour | Palette name | Used for |
|---|---|---|
| `#a3aed2` | `fg_dark` | OS pill |
| `#090c0c` | `bg_dark` | OS icon |
| `#769ff0` | `blue` | directory pill, git text |
| `#e3e5e5` | `bg_dark` | directory text: dark on blue, like lualine's NORMAL |
| `#394260` | `fg_gutter` | git pill |
| `#212736` | `bg_highlight` | language pill |
| `#1d2230` | `bg_dark` | time pill |
| `#a0a9cb` | `fg_dark` | time text |

In `format`, replace `$nodejs $bun $rust $golang $php` with `$c $python $conda $lua`, and add `$cmd_duration` before `$time`. Then:

```toml
palette = "tokyonight_night"
command_timeout = 1000

[palettes.tokyonight_night]
bg = "#1a1b26"
bg_dark = "#16161e"
bg_highlight = "#292e42"
fg = "#c0caf5"
fg_dark = "#a9b1d6"
fg_gutter = "#3b4261"
comment = "#565f89"
blue = "#7aa2f7"
cyan = "#7dcfff"
green = "#9ece6a"
magenta = "#bb9af7"
red = "#f7768e"
yellow = "#e0af68"

[directory]
style = "fg:bg_dark bg:blue"   # every module now uses palette names instead of hex

[cmd_duration]                 # new: shows commands that ran for 2 s or more
min_time = 2000
format = "[[ $duration ](fg:yellow bg:bg_dark)]($style)"
style = "bg:bg_dark"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold magenta)"
```

### 5.4 CLI tools

| Tool | Change | File(s) in the repo |
|---|---|---|
| bat | a config file instead of `BAT_THEME`; `bat cache --build` in `install.sh`; also used as `MANPAGER` | `bat/config` |
| **delta** (new) | pager for git and lazygit; `syntax-theme = tokyonight_night` (delta reads bat's theme cache) plus folke's diff colours | `git/config`, `theme/delta.gitconfig` |
| eza | Tokyo Night theme (eza reads `~/.config/eza/theme.yml`) | `eza/theme.yml` ← folke `eza/tokyonight_night.yml` |
| fzf | a theme file instead of the inline string; fd as the source; bat/eza previews | `theme/fzf.sh` ← folke `fzf/tokyonight_night.sh` |
| lazygit | config in `~/.config` (needs `XDG_CONFIG_HOME`), Tokyo Night, delta | `lazygit/config.yml` ← folke `lazygit/tokyonight_night.yml` + snippet below |
| **yazi** (new) | theme and the `y` wrapper; image previews work in Ghostty | `yazi/theme.toml` ← folke `yazi/tokyonight_night.toml` |
| btop | `color_theme = "tokyonight_night"`, `theme_background = false`, `vim_keys = true`, `rounded_corners = true`, `save_config_on_exit = false` | `btop/btop.conf`, `btop/themes/` ← folke `btop/tokyonight_night.theme` |
| **vivid** (new) | `LS_COLORS` from the palette, for zsh completion, fd and tree | — |
| fastfetch (optional) | palette colours and a small logo, for screenshots | `fastfetch/config.jsonc` |
| tmux | Not now: yabai tiles Ghostty windows, and Ghostty has tabs. Later, for persistent sessions: folke `tmux/tokyonight_night.tmux` + vim-tmux-navigator | — |
| lsd | uninstall | — |

`bat/config`:

```text
--theme="tokyonight_night"
--style="numbers,changes,header"
--italic-text=always
```

`git/config` is included from `~/.gitconfig`, so your name and e-mail stay there:

```ini
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    line-numbers = true
    syntax-theme = tokyonight_night
[merge]
    conflictStyle = zdiff3
[include]
    path = ~/.dotfiles/theme/delta.gitconfig
```

`lazygit/config.yml` follows the lazygit 0.66 docs, which configure this as `git.diffRenderers`. Older guides show `git.paging`.

```yaml
# gui: …  <- paste the contents of folke's extras/lazygit/tokyonight_night.yml here
git:
  diffRenderers:
    - command: delta --{{colorScheme}} --paging=never
```

### 5.5 yabai

Add to `yabairc`. The keys come from `man yabai` for 7.1.25.

```sh
source "$HOME/.dotfiles/theme/colors.sh"

yabai -m config window_shadow float              # shadows only on floating windows
yabai -m config insert_feedback_color $TN_BLUE
yabai -m config mouse_modifier fn                # fn + drag = move, fn + right-drag = resize
yabai -m config mouse_action1 move
yabai -m config mouse_action2 resize
yabai -m config mouse_drop_action swap

# spaces that should always float (today this is runtime state, lost on restart)
yabai -m config --space 2 layout float
yabai -m config --space 3 layout float

# unmanaged apps — localized names count; check with: yabai -m query --windows | jq '.[].app'
yabai -m rule --add app="^(Ustawienia systemowe|System Settings|Kalkulator|Calculator|Monitor aktywności|Activity Monitor|Karabiner-Elements|Karabiner-EventViewer|LinearMouse)$" manage=off
yabai -m rule --apply                            # rules also apply to already-open windows
```

Two more things:
- Turn *Displays have separate Spaces* on in System Settings → Desktop & Dock → Mission Control, then log out. `macos.sh` (§5.9) does the same.
- After every `brew upgrade yabai`, refresh the sudoers hash. Otherwise `sudo yabai --load-sa` asks for a password:

```bash
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 "$(command -v yabai)" | cut -d' ' -f1) $(command -v yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
```

### 5.6 Karabiner-Elements + skhd

This is the Karabiner rule, a complex modification in `karabiner/karabiner.json`. Symlink the whole `~/.config/karabiner` **directory**, not the file: Karabiner does not notice changes when `karabiner.json` itself is a symlink.

```json
{
  "description": "Caps Lock: tap = Escape, hold = Control+Option (window-manager key)",
  "manipulators": [
    {
      "type": "basic",
      "from": { "key_code": "caps_lock", "modifiers": { "optional": ["any"] } },
      "to": [{ "key_code": "left_control", "modifiers": ["left_option"] }],
      "to_if_alone": [{ "key_code": "escape" }]
    }
  ]
}
```

With Caps held as ⌃⌥, all your current skhd bindings become one-handed without any edits. Changes to `skhdrc`:

```text
# spaces 1–9 (SketchyBar shows only those that exist)
ctrl + alt - 5 : yabai -m space --focus 5            # … same pattern up to 9
shift + ctrl + alt - 5 : yabai -m window --space 5; yabai -m space --focus 5

# a new window in the running Ghostty (AppleScript, Ghostty >= 1.3) instead of a new process
ctrl + alt - return : osascript -e 'if application "Ghostty" is running then' -e 'tell application "Ghostty" to new window' -e 'else' -e 'tell application "Ghostty" to activate' -e 'end if'

# resize, split direction, restart
ctrl + alt - left  : yabai -m window --resize left:-50:0  || yabai -m window --resize right:-50:0
ctrl + alt - right : yabai -m window --resize right:50:0  || yabai -m window --resize left:50:0
ctrl + alt - up    : yabai -m window --resize top:0:-50   || yabai -m window --resize bottom:0:-50
ctrl + alt - down  : yabai -m window --resize bottom:0:50 || yabai -m window --resize top:0:50
ctrl + alt - s : yabai -m window --toggle split
shift + ctrl + alt - r : yabai --restart-service
```

Leave `ctrl + alt - g` unbound in skhd so that Ghostty's global quick-terminal key works. The first run of the AppleScript line asks for the Automation permission (skhd → Ghostty).

### 5.7 JankyBorders

```bash
#!/bin/bash
source "$HOME/.dotfiles/theme/colors.sh"
options=(
  style=round
  width=5.0
  hidpi=on
  active_color="gradient(top_left=$TN_BLUE,bottom_right=$TN_MAGENTA)"
  inactive_color=$TN_GUTTER
)
borders "${options[@]}"
```

The gradient picks up the prompt's blue and the magenta of the front-app label. For a calmer look, use `active_color=$TN_BLUE`.

### 5.8 SketchyBar

```text
sketchybar/
├── sketchybarrc          # bar + defaults; sources theme/colors.sh and items/*
├── icons.sh              # Nerd Font glyphs in one place
├── helpers/icon_map.sh   # from the sketchybar-app-font v3.0.5 release
├── items/                # spaces.sh front_app.sh clock.sh battery.sh volume.sh
└── plugins/              # event scripts (as today)
```

- **Geometry:** set `y_offset=8`, so the bar ends at y = 40, the area yabai reserves.
- **Colours:** take them from `theme/colors.sh`.
- **Spaces with app icons:**
  - Subscribe to `space_windows_change`. Its `$INFO` is JSON with the space and its apps.
  - Map each app name with `__icon_map "$app"`, which sets `$icon_result` (e.g. `:ghostty:`), and draw it with `sketchybar-app-font:Regular:16.0`.
  - Apple apps may report Polish names, such as "Ustawienia systemowe"; add `case` entries for those.
  - The active space is a `blue` pill; the others use `comment`.
- **front_app:** app icon plus name, in magenta.
- **Right side:** clock `%a %d.%m  %H:%M`, battery, volume, and optionally a Wi-Fi icon.
- **Notch:** keep items on the left and right, with nothing in the centre, because the notch covers the middle of the bar.
- **No now-playing widget:** the `media_change` event is deprecated on macOS 26.
- **Later, if the bar grows:** port it to SbarLua, which is event-driven and doesn't start a shell per update. The bar author's own setup ([FelixKratz/dotfiles](https://github.com/FelixKratz/dotfiles)) is a good reference.

### 5.9 macOS settings (`macos.sh`)

```bash
#!/bin/bash
# Mission Control — required by yabai
defaults write com.apple.spaces spans-displays -bool false   # Displays have separate Spaces: ON
defaults write com.apple.dock mru-spaces -bool false         # don't reorder Spaces (already set)
# Keyboard — fast key repeat for Vim motions (press-and-hold is already off)
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
# Snappier windows with a tiling WM
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
# Dock hidden (already set; kept for a fresh machine)
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
killall Dock
echo "Log out and back in to apply everything."
```

The menu bar is already hidden (*Automatically hide and show the menu bar* → Always). On a new machine, set that by hand.

## 6. Neovim from scratch: plugin plan

### 6.1 Approach

- **Plugin manager: the built-in `vim.pack`** (Neovim 0.12).
  - It needs no bootstrap code, and its lockfile, `nvim-pack-lock.json`, is committed with the config.
  - kickstart.nvim now uses it too, so the best-known learning resource matches your setup. You learn Neovim, not a plugin manager.
  - Trade-off: there is no declarative lazy-loading (`event =`, `cmd =`). Where it matters, use an autocmd or `vim.schedule()`, and measure with `nvim --startuptime`.
- **Learning path:**
  - Read kickstart.nvim's `init.lua` as a commented reference, but don't copy it wholesale.
  - Build your own modular config, phase by phase.
  - The LazyVim backup stays usable through `NVIM_APPNAME=nvim-lazy-config nvim` (the `nvim-old` alias).
- **Clean start:** remove the old experiments and the stray lockfile together. Otherwise `vim.pack` reinstalls whatever the lockfile lists.
  - This keeps your shada and undo history.
  - The backup's data lives separately, in `~/.local/share/nvim-lazy-config`.

```bash
rm -rf ~/.local/share/nvim/{site,lazy,mason,snacks} ~/.dotfiles/nvim/nvim-pack-lock.json ~/.local/state/nvim/lsp.log
```

`~/.local/share/nvim-test` and `~/.local/share/nvime-test` also look like leftovers from earlier tests.

### 6.2 Layout

```text
nvim/
├── init.lua                  # loader, leader, require('config.*')
├── nvim-pack-lock.json       # written by vim.pack — commit it
├── lua/config/
│   ├── options.lua
│   ├── keymaps.lua
│   ├── autocmds.lua
│   └── pack.lua              # PackChanged build hooks (must run before any vim.pack.add)
├── plugin/                   # sourced automatically after init.lua, alphabetically
│   ├── 10-ui.lua             # colourscheme, statusline, icons, which-key
│   ├── 20-treesitter.lua
│   ├── 30-lsp.lua            # lspconfig, mason, diagnostics
│   ├── 40-completion.lua     # blink.cmp
│   ├── 50-format.lua         # conform
│   ├── 60-navigation.lua     # fzf-lua, yazi.nvim, mini.*
│   └── 70-git.lua            # gitsigns, lazygit
└── after/ftplugin/           # per-language tweaks (cpp.lua, python.lua, …)
```

### 6.3 Starting skeleton

This was tested headless on Neovim 0.12.5 in an isolated sandbox:
- the plugins install through `vim.pack`;
- `tokyonight-night` loads, with the `Normal` background at `#1a1b26`;
- lualine (with the U+E0B4 separator) and mini.icons start.

On first start, `vim.pack` asks you to confirm installing the plugins.

`init.lua`:

```lua
vim.loader.enable()
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.pack') -- PackChanged build hooks: must exist before the first vim.pack.add()
-- Files in plugin/ are sourced automatically after init.lua, in alphabetical order.
```

`lua/config/options.lua`:

```lua
local o = vim.o
o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.scrolloff = 8
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.updatetime = 250
o.timeoutlen = 300
o.showmode = false        -- the statusline shows the mode
o.winborder = 'rounded'   -- all floating windows (hover, diagnostics, pickers)
o.pumborder = 'rounded'   -- completion menu (0.12)
o.list = true
o.listchars = 'tab:» ,trail:·,nbsp:␣'
o.inccommand = 'split'
o.confirm = true
vim.schedule(function() o.clipboard = 'unnamedplus' end)

require('vim._core.ui2').enable() -- experimental message/cmdline UI (0.12)
```

`lua/config/pack.lua`:

```lua
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end,
})
```

`plugin/10-ui.lua`:

```lua
vim.pack.add({
  'https://github.com/folke/tokyonight.nvim',
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/nvim-lualine/lualine.nvim',
})

require('tokyonight').setup({ style = 'night' })
vim.cmd.colorscheme('tokyonight-night')

require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons() -- plugins expecting nvim-web-devicons get mini.icons

require('lualine').setup({
  options = {
    theme = 'tokyonight',
    globalstatus = true,
    -- the same rounded pills as the starship prompt (U+E0B4 / U+E0B6)
    section_separators = { left = '\u{e0b4}', right = '\u{e0b6}' },
    component_separators = { left = '\u{e0b5}', right = '\u{e0b7}' },
  },
})
```

### 6.4 Plugin plan by phase

**Phase 0 — built-ins only (one evening).** Set up options, keymaps and autocmds (e.g. highlight on yank). Then learn what 0.12 already gives you:
- LSP keys: `grn` rename, `gra` code action, `grr` references, `gri` implementation, `grt` type definition, `gO` symbols, `K` hover, `[d` / `]d` diagnostics.
- In Visual mode, `an` / `in` grow and shrink the selection by treesitter node.
- `:Undotree`, `:DiffTool` and `:restart`.
- `require('vim._core.ui2').enable()`, the new experimental message and cmdline UI with no more "Press ENTER". For most people it replaces noice.nvim.

*Done when* you can edit comfortably and find things in `:help`.

**Phase 1 — Look**

| Plugin | Purpose | Note |
|---|---|---|
| `folke/tokyonight.nvim` | colourscheme | `style = 'night'` |
| `nvim-lualine/lualine.nvim` | statusline | rounded separators match the starship pills |
| `nvim-mini/mini.nvim` → `mini.icons` | icons | `mock_nvim_web_devicons()` |
| `folke/which-key.nvim` | shows pending keys and leader groups | |
| `j-hui/fidget.nvim` | LSP progress and `vim.notify` | |
| `mini.indentscope` | scope line | |
| `mini.hipatterns` | colours `#rrggbb` in place, highlights TODO/FIXME | handy when editing theme files |

**Phase 2 — Code intelligence**

| Plugin | Purpose | Note |
|---|---|---|
| `nvim-treesitter/nvim-treesitter` (`version = 'main'`) | parsers; highlighting, indent, folds | needs tree-sitter CLI ≥ 0.26.1 (you have 0.27.0); start it with `vim.treesitter.start()` in a `FileType` autocmd; no lazy-loading |
| `neovim/nvim-lspconfig` | server definitions for `vim.lsp.config` / `vim.lsp.enable` | |
| `mason-org/mason.nvim` + `mason-org/mason-lspconfig.nvim` | install servers and enable them automatically | |
| `WhoIsSethDaniel/mason-tool-installer.nvim` | install formatters and linters | |
| `saghen/blink.cmp` (`version = vim.version.range('1.*')`) | completion; the release tag brings a prebuilt fuzzy matcher | |
| `rafamadriz/friendly-snippets` | snippets for blink | |
| `stevearc/conform.nvim` | format on save | |
| `lua_ls` settings as in kickstart (or `folke/lazydev.nvim`) | Neovim API completion while editing your config | |

**Phase 3 — Navigation and editing**

| Plugin | Purpose | Note |
|---|---|---|
| `ibhagwan/fzf-lua` | files, grep, buffers, LSP symbols, help | the same fzf as in the shell |
| `mikavilpas/yazi.nvim` | file manager in a float | the same yazi as in the shell |
| `mini.ai`, `mini.surround`, `mini.pairs` | text objects, surround, auto-pairs | |
| `folke/flash.nvim` | jump anywhere with 2–3 keys | optional |
| `folke/trouble.nvim` | diagnostics and quickfix list | optional |

**Phase 4 — Git and extras**

| Plugin | Purpose | Note |
|---|---|---|
| `lewis6991/gitsigns.nvim` | signs, stage/preview hunks, blame | |
| `kdheepak/lazygit.nvim` | `<leader>gg` opens lazygit in a float | or a 10-line `:terminal` helper |
| `MeanderingProgrammer/render-markdown.nvim` | rendered Markdown in the buffer | nice for Obsidian notes |
| `nvim-treesitter/nvim-treesitter-context` | sticky function header | optional |
| `mfussenegger/nvim-dap` + `rcarriga/nvim-dap-ui` + codelldb (Mason) | C/C++ debugging | later |

Alternatives, if you prefer them:
- **`folke/snacks.nvim`:** one plugin providing a picker, explorer, lazygit, dashboard and notifier. It replaces fzf-lua, fidget and lazygit.nvim.
- **`telescope.nvim`:** the picker kickstart uses.
- **`stevearc/oil.nvim` or `mini.files`:** instead of yazi.nvim.
- **`lazy.nvim`:** instead of `vim.pack`.

### 6.5 Languages (based on your Homebrew packages)

| Language | LSP | Formatter / linter | Treesitter parsers |
|---|---|---|---|
| Lua (Neovim config) | `lua_ls` | stylua | lua, luadoc, vim, vimdoc, query |
| C / C++ | `clangd` | clang-format (Homebrew) | c, cpp |
| CMake | `neocmake` | — | cmake |
| Python | `basedpyright` + `ruff` | ruff | python |
| Swift (xcodegen projects) | `sourcekit`, from Xcode, not Mason | — | swift |
| Shell | `bashls` | shfmt, shellcheck | bash |
| Markdown | `marksman` | prettier (optional) | markdown, markdown_inline |
| TOML / YAML / JSON | `taplo` / `yamlls` / `jsonls` | taplo / prettier | toml, yaml, json |
| Optional | `postgres_lsp` (SQL), `prolog_ls` (Prolog), `texlab` + vimtex (LaTeX), `vtsls` (JS/TS) | | |

All of these server names exist in nvim-lspconfig's `lsp/` directory today.

### 6.6 Key conventions

| Prefix | Group | Examples |
|---|---|---|
| `<leader>f` | find (fzf-lua) | `ff` files · `fg` grep · `fb` buffers · `fh` help |
| `<leader>g` | git | `gg` lazygit · `gb` blame line · `gp` preview hunk |
| `<leader>c` | code | `cf` format · `cd` line diagnostics |
| `<leader>e` | explorer | yazi at the current file |
| `gr…` | LSP (built-in) | `grn` `gra` `grr` `gri` `grt` |
| `<C-h/j/k/l>` | windows | move between splits |

## 7. What is missing

`brew bundle check` against the draft Brewfile (§8) reports exactly these as not installed: 2 casks and 11 formulae.

| Priority | Item | Why |
|---|---|---|
| Must | `zsh-autosuggestions`, `zsh-fast-syntax-highlighting`, `zsh-completions`, `fzf-tab` | modern shell UX |
| Must | `git-delta` | readable diffs in git and lazygit |
| Must | `karabiner-elements` (cask) | Caps Lock = Esc / WM key |
| Must | `font-sketchybar-app-font` (cask) | app icons in the bar |
| Must | `Brewfile`, `macos.sh`, a tracked git config | reproducibility |
| Should | `yazi`, plus preview helpers `sevenzip`, `poppler`, `resvg`, `imagemagick` | one file manager in the shell and in Neovim |
| Should | `vivid` | `LS_COLORS` from the palette |
| Optional | `tealdeer` | `tldr` examples |
| Optional | `atuin` | searchable shell history; fzf's `Ctrl-R` is enough to start |
| Optional | Tokyo Night themes for VS Code and Obsidian, a wallpaper in the palette | consistency outside the terminal |
| Remove | `lsd` | duplicates eza |
| Remove? | `stow` | unused while `install.sh` does the linking |

## 8. Repository layout and install scripts

```text
~/.dotfiles
├── Brewfile                 # brew bundle --file ~/.dotfiles/Brewfile
├── install.sh               # symlinks + git include + bat cache (idempotent)
├── macos.sh                 # defaults write …, run once, then log out
├── README.md                # what lives where + keybinding cheat-sheet
├── theme/                   # single source of truth for colours
│   ├── colors.sh            # 0xAARRGGBB for SketchyBar / JankyBorders / yabai
│   ├── fzf.sh               # folke extras
│   └── delta.gitconfig      # folke extras
├── bat/        config, themes/
├── borders/    bordersrc
├── btop/       btop.conf, themes/
├── eza/        theme.yml
├── ghostty/    config, themes/tokyonight_night
├── git/        config              (included from ~/.gitconfig)
├── karabiner/  karabiner.json      (symlink the directory)
├── lazygit/    config.yml
├── nvim/  nvim-lazy-config/
├── sketchybar/ sketchybarrc, items/, plugins/, helpers/
├── skhd/  starship/  yabai/
├── yazi/       theme.toml
└── zsh/        .zshrc, .zprofile
```

`install.sh` gets one `link` function and a list. It is idempotent and passes `bash -n`:

```bash
#!/bin/bash
# Links configs from ~/.dotfiles into place. Safe to run repeatedly.
set -euo pipefail
DOT="$HOME/.dotfiles"

link() { # link <path in repo> <target>
  local src="$DOT/$1" dst="$2"
  [ -e "$src" ] || { echo "missing $src"; return; }
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "skip $dst: a real file/dir exists, move it into the repo first"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "linked $dst"
}

for d in yabai skhd sketchybar borders ghostty btop bat eza lazygit yazi karabiner nvim nvim-lazy-config; do
  link "$d" "$HOME/.config/$d"
done
link starship/starship.toml "$HOME/.config/starship.toml"
link zsh/.zshrc             "$HOME/.zshrc"
link zsh/.zprofile          "$HOME/.zprofile"

# git: identity stays in ~/.gitconfig, the shared part is included
git config --global --get-all include.path | grep -qxF "$DOT/git/config" \
  || git config --global --add include.path "$DOT/git/config"

bat cache --build >/dev/null && echo "bat theme cache rebuilt"
```

For the `Brewfile`, start with `brew bundle dump --describe --file ~/.dotfiles/Brewfile` and then curate it. The terminal part (parses with `brew bundle list`):

```ruby
# Brewfile — terminal & desktop setup (add the dev toolchain from `brew bundle dump`)
tap "asmvik/formulae"
tap "felixkratz/formulae"

# Desktop
brew "asmvik/formulae/yabai"
brew "asmvik/formulae/skhd"
brew "felixkratz/formulae/sketchybar"
brew "felixkratz/formulae/borders"
cask "ghostty"
cask "karabiner-elements"
cask "font-jetbrains-mono-nerd-font"
cask "font-sketchybar-app-font"
cask "sf-symbols"

# Shell
brew "starship"
brew "zoxide"
brew "fzf"
brew "fzf-tab"
brew "zsh-autosuggestions"
brew "zsh-fast-syntax-highlighting"
brew "zsh-completions"
brew "vivid"

# Terminal tools
brew "bat"
brew "eza"
brew "fd"
brew "ripgrep"
brew "git"
brew "git-delta"
brew "gh"
brew "lazygit"
brew "yazi"
brew "sevenzip"     # yazi previews: archives
brew "poppler"      # yazi previews: PDF
brew "resvg"        # yazi previews: SVG
brew "imagemagick"  # yazi previews: other images
brew "btop"
brew "fastfetch"
brew "tmux"

# Neovim
brew "neovim"
brew "tree-sitter-cli"
brew "node"         # several Mason language servers need it
```

Then add your development toolchain from the dump: cmake, clang-format, python, postgresql@16, redis, swi-prolog, xcodegen, miniconda, and so on.

On a new Mac, run `brew bundle` → `./install.sh` → `./macos.sh`, then log out.

## 9. Roadmap

**Phase A — Foundation (one evening)**
- [ ] Answer the questions in §10.
- [ ] `theme/`: `colors.sh`, the folke extras (fzf, delta), and the theme files for Ghostty, btop, eza, lazygit and yazi.
- [ ] `Brewfile`: dump, curate, install what is missing, uninstall `lsd`.
- [ ] `install.sh`: the `link` function, the new targets, `bat cache --build`, the git include.
- [ ] Move `~/.zprofile` into `zsh/`.
- [ ] `macos.sh`: separate Spaces on, key repeat; then log out.

*Done when:*
- `brew bundle check` passes;
- running `./install.sh` twice changes nothing;
- `rg -i storm ~/.dotfiles --glob '!nvim-lazy-config'` finds nothing (today it lists `ghostty/config` and `btop/btop.conf`).

**Phase B — Terminal (1–2 evenings)**
- [ ] Ghostty config (§5.1).
- [ ] `.zshrc` (§5.2); `time zsh -i -c exit` under 0.1 s.
- [ ] Starship palette and modules (§5.3).
- [ ] bat, eza, fzf, delta, lazygit, yazi, btop (§5.4).

*Done when* the prompt, `ll`, `bat`, `git diff`, `lg`, `y` and `btop` all show the same palette in a translucent window.

**Phase C — Desktop (1–2 evenings)**
- [ ] Karabiner: the Caps Lock rule and a symlinked `~/.config/karabiner` directory.
- [ ] skhd: spaces 1–9, the AppleScript window, resize, restart (§5.6).
- [ ] yabai: colours, rules + `--apply`, mouse, shadows, per-space layouts (§5.5).
- [ ] JankyBorders: the palette gradient (§5.7).
- [ ] SketchyBar: `y_offset=8`, the new structure, app icons, front-app icon, clock format (§5.8).

*Done when:*
- the 8 px rhythm holds everywhere;
- you manage windows one-handed with Caps;
- the bar shows app icons for each space.

**Phase D — Neovim (2–4 weeks, a bit at a time)**
- [ ] Clean start (§6.1) and the skeleton (§6.3).
- [ ] Phases 0 → 4 (§6.4), committing `nvim-pack-lock.json` after each one.

*Done when* you use it every day for C++ and Python and no longer reach for VS Code.

**Phase E — Polish (optional)**
- [ ] Ghostty icon, wallpaper, fastfetch, VS Code and Obsidian themes.
- [ ] A README with a keybinding cheat-sheet.

## 10. Decisions to confirm

| # | Question | Recommendation |
|---|---|---|
| 1 | Palette variant | **Night** (alternative: Storm, but everywhere) |
| 2 | Inside Ghostty, type Polish letters with **right ⌥** only, so left ⌥ = Alt | yes |
| 3 | Caps Lock = Esc / ⌃⌥ via Karabiner | yes (alternative: full Hyper ⌘⌃⌥⇧ and a rewritten skhdrc) |
| 4 | Neovim plugin manager | **vim.pack** (alternative: lazy.nvim) |
| 5 | Picker | **fzf-lua** (alternatives: telescope, snacks.picker) |
| 6 | File manager | **yazi + yazi.nvim** (alternatives: oil.nvim, mini.files) |
| 7 | Languages to set up first | C/C++, Python and Lua are assumed. Swift? LaTeX? SQL? Prolog? |
| 8 | Blur | `background-blur = 20` (alternative: `macos-glass-regular`) |
| 9 | Quick-terminal key | ⌃⌥G = Caps + G |

## 11. Verification and references

How the snippets were checked on this Mac (2026-10-05):

| Snippet | Check |
|---|---|
| Ghostty config | `ghostty +validate-config` (1.3.1), with folke's theme file present; a missing theme is reported, so the file was found |
| `.zshrc` | `zsh -n`; plugin paths from `brew info` caveats |
| Starship | `starship prompt` and `starship explain` (1.26.0) with the palette config; no warnings |
| Neovim skeleton | headless `nvim` 0.12.5 with isolated XDG directories: plugins installed, colourscheme and lualine loaded |
| Karabiner rule | valid JSON; directory-symlink rule from the Karabiner docs |
| skhd → Ghostty AppleScript | `osacompile` against Ghostty 1.3.1's scripting dictionary |
| yabai keys | `man yabai` (7.1.25) |
| `install.sh` | `bash -n` |
| Brewfile | `brew bundle list` / `brew bundle check` |
| lazygit | `docs/Custom_DiffRenderers.md` at tag v0.66.0 |

References:
- folke/tokyonight.nvim extras — <https://github.com/folke/tokyonight.nvim/tree/main/extras>
- Ghostty options — `ghostty +show-config --default --docs`, <https://ghostty.org/docs/config/reference>
- Neovim 0.12 — `:help news`, `:help vim.pack`; *A guide to vim.pack* — <https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack>
- kickstart.nvim — <https://github.com/nvim-lua/kickstart.nvim>
- nvim-treesitter (main) — <https://github.com/nvim-treesitter/nvim-treesitter>
- yabai — <https://github.com/asmvik/yabai> (wiki: <https://github.com/asmvik/yabai/wiki>)
- SketchyBar events — <https://felixkratz.github.io/SketchyBar/config/events>
- sketchybar-app-font — <https://github.com/kvndrsslr/sketchybar-app-font>
- JankyBorders — <https://github.com/FelixKratz/JankyBorders/wiki/Man-Page>
- Karabiner config path — <https://karabiner-elements.pqrs.org/docs/manual/misc/configuration-file-path/>
- lazygit diff renderers — <https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_DiffRenderers.md>
- delta and bat themes — <https://dandavison.github.io/delta/supported-languages-and-themes.html>
- yazi quick start — <https://yazi-rs.github.io/docs/quick-start>
