# small changes to clanki, applied when it starts (clanki itself stays untouched,
# so uv tool upgrade doesn't wipe them)
#
# 1. smoother card changes - clanki swaps the card by removing the old box and
#    mounting a new one, textual can draw a frame in between with no card,
#    here both steps happen in one batch so only the finished card gets drawn
# 2. progress bar at the bottom - done this session (dim) + what's left
#    (new blue, learning red, review green), counts and percent under it
# 3. right cmd rates Hard after the answer shows up (like space rates Good)
# 4. media sync finishes before clanki closes the collection (fixes a panic)
#
# each part is separate - if a clanki update breaks one, the rest still works
#
# run it with clanki's own python (scripts/anki does that):
#   ~/.local/share/uv/tools/clanki/bin/python ~/.dotfiles/clanki/tweaks.py

import sys

# 1. smoother card changes
try:
    from textual.containers import Vertical
    from textual.widgets import Static
    from clanki.render import RenderMode
    from clanki.tui.widgets.card_view import CardViewWidget

    async def swap(view, section, html):
        async with view.batch():
            try:
                await view.remove_children()
                await view.mount(section)
            except Exception:
                # same fallback as the original: plain text
                await view.remove_children()
                await view.mount(Static(html, classes="content"))

    def refresh_content(self):
        if self._answer_html is not None:
            html = self._answer_html
            widgets = self._render_section_content(html, mode=RenderMode.ANSWER)
        else:
            html = self._question_html
            widgets = self._render_section_content(html, mode=RenderMode.QUESTION)
        section = Vertical(*widgets, classes="card-section")
        # exclusive - pressing keys fast cancels the old swap, only the last card shows up
        self.run_worker(swap(self, section, html), group="card-swap",
                        exclusive=True, exit_on_error=False)

    CardViewWidget._refresh_content = refresh_content
except Exception as e:
    print(f"smooth cards skipped: {e}", file=sys.stderr)

# 2. progress bar
try:
    from rich.text import Text
    from clanki.tui.widgets.stats_bar import DeckCountsBar

    # same colors clanki uses for the counts
    NEW = "#5eb5f7"
    LEARN = "#e96c6c"
    REVIEW = "#6cd97e"
    # how thick the bar is, in terminal rows (full block cells)
    BAR_ROWS = 1
    BAR_CHAR = "█"

    def bar_render(self):
        try:
            done = self.app.state.stats.reviewed
        except Exception:
            done = 0

        parts = [(done, "dim"), (self._new, NEW), (self._learn, LEARN), (self._review, REVIEW)]
        total = done + self._new + self._learn + self._review
        width = self.size.width

        bar = Text()
        if total > 0 and width > 0:
            # how many cells each part gets, anything non-zero gets at least one
            cells = []
            for n, color in parts:
                k = round(n * width / total)
                if n > 0 and k == 0:
                    k = 1
                cells.append(k)
            # rounding can be off by a few cells, the biggest part takes the difference
            big = cells.index(max(cells))
            cells[big] = max(0, cells[big] + width - sum(cells))
            for i in range(len(parts)):
                bar.append(BAR_CHAR * cells[i], style=parts[i][1])

        pct = done * 100 // total if total > 0 else 0
        line = Text.from_markup(
            f"[dim]{done} done[/dim]   "
            f"[bold {NEW}]{self._new}[/] New   "
            f"[bold {LEARN}]{self._learn}[/] Learning   "
            f"[bold {REVIEW}]{self._review}[/] Review   "
            f"[dim]{pct}%[/dim]"
        )

        out = Text(justify="center")
        for row in range(BAR_ROWS):
            out.append_text(bar)
            out.append("\n")
        out.append_text(line)
        return out

    DeckCountsBar.render = bar_render
    # counts changed -> just redraw, render() builds everything
    DeckCountsBar._refresh_display = lambda self: self.refresh()
    DeckCountsBar.DEFAULT_CSS = f"""
    DeckCountsBar {{
        height: {BAR_ROWS + 1};
        text-align: center;
    }}
    """
except Exception as e:
    print(f"progress bar skipped: {e}", file=sys.stderr)

# 3. right cmd = Hard (space = show answer, then space = Good / right cmd = Hard)
# textual turns on kitty's full keyboard protocol, so a lone right cmd press
# comes in as "right_super" - works straight in kitty, not through tmux
try:
    from clanki.tui.screens.review import ReviewScreen

    old_init = ReviewScreen.__init__
    old_help = ReviewScreen._get_help_text

    def review_init(self, *args, **kwargs):
        old_init(self, *args, **kwargs)
        self._bindings.bind("right_super", "rate_hard", "Hard", show=False)

    def review_help(self):
        text = old_help(self)
        return text.replace("[bold yellow]2[/bold yellow] Hard",
                            "[bold yellow]2/⌘[/bold yellow] Hard")

    ReviewScreen.__init__ = review_init
    ReviewScreen._get_help_text = review_help
except Exception as e:
    print(f"right cmd = hard skipped: {e}", file=sys.stderr)

# 4. media sync waits until it's done
# anki runs media sync in its own thread, clanki starts it and closes the
# collection right away, the thread finds no collection and panics
# (rslib/src/backend/sync.rs:249, Option::unwrap) - wait for it before closing
try:
    import time
    from anki.collection import Collection

    old_sync_media = Collection.sync_media

    def sync_media_wait(self, auth):
        old_sync_media(self, auth)
        start = time.time()
        while time.time() - start < 120:
            try:
                if not self.media_sync_status().active:
                    break
            except Exception:
                # media sync failed - cards are already synced, just skip media
                break
            time.sleep(0.2)

    Collection.sync_media = sync_media_wait
except Exception as e:
    print(f"media sync wait skipped: {e}", file=sys.stderr)

from clanki.cli import main

sys.exit(main())
