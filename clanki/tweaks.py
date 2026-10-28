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
# 5. e opens the current note in nvim to edit it, u right after undoes the edit
# 6. the answer side keeps the front of the card above a line (like anki desktop)
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

# 5. e = edit the current note in nvim ($EDITOR if set)
# every field becomes a "## Name" section, <br> shows up as a new line
# the edit is a normal anki undo step, so u right after it undoes the edit
# (and u after rating still undoes the rating - it only takes the edit when
# that's what's on top of anki's undo stack)
try:
    import os
    import re
    import shlex
    import subprocess
    import tempfile
    import time
    from textual.app import SuspendNotSupported
    from clanki.review.session import _extract_audio_filenames
    from clanki.tui.screens.review import ReviewScreen

    def field_to_text(value):
        return re.sub(r"<br\s*/?>", "\n", value, flags=re.IGNORECASE)

    def text_to_field(text):
        return text.replace("\n", "<br>")

    def note_to_file(note, deck):
        lines = [
            f"# editing a note from {deck}",
            "# every field starts with its ## line, change the text under it,",
            "# save and quit (:wq) to apply, quit without saving (:q!) to cancel",
            "",
        ]
        for name in note.keys():
            lines.append(f"## {name}")
            lines.append(field_to_text(note[name]))
            lines.append("")
        return "\n".join(lines)

    def file_to_fields(text, names):
        # only "## <field name>" lines start a field, in the note's own order
        fields = {}
        current = None
        left = list(names)
        for line in text.split("\n"):
            if left and line == f"## {left[0]}":
                current = left.pop(0)
                fields[current] = []
                continue
            if current is not None:
                fields[current].append(line)
        out = {}
        for name in fields:
            out[name] = "\n".join(fields[name]).strip("\n")
        return out

    def run_editor(app, path):
        editor = shlex.split(os.environ.get("EDITOR") or "nvim") + [path]
        log_edit(f"running {editor}")
        try:
            with app.suspend():
                res = subprocess.run(editor)
        except SuspendNotSupported:
            log_edit("suspend not supported, running without it")
            res = subprocess.run(editor)
        log_edit(f"editor exited with {res.returncode}")

    def rerender(screen):
        cur = screen._current_card
        if cur is None:
            return
        cur.card.note(reload=True)
        out = cur.card.render_output(reload=True)
        cur.question_html = out.question_and_style()
        cur.answer_html = out.answer_and_style()
        cur.question_audio = _extract_audio_filenames(out.question_av_tags)
        cur.answer_audio = _extract_audio_filenames(out.answer_av_tags)
        screen._display_card(play_audio=False)

    def log_edit(msg):
        # ~/.cache/clanki-edit.log - what happened on the last few e presses
        try:
            path = os.path.expanduser("~/.cache/clanki-edit.log")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "a") as f:
                f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")
        except Exception:
            pass

    async def action_edit_card(self):
        import traceback
        log_edit(f"e pressed, EDITOR={os.environ.get('EDITOR')!r}, TERM={os.environ.get('TERM')!r}, TMUX={bool(os.environ.get('TMUX'))}")
        try:
            await edit_card(self)
        except Exception as exc:
            log_edit("error:\n" + traceback.format_exc())
            self.notify(f"Edit failed: {exc} (see ~/.cache/clanki-edit.log)", severity="error", timeout=10)

    async def edit_card(self):
        cur = self._current_card
        col = self.clanki_app.state.col
        if cur is None or col is None:
            return
        try:
            from clanki.audio import stop_audio
            stop_audio()
        except Exception:
            pass

        note = cur.card.note(reload=True)
        names = note.keys()
        before = {}
        for name in names:
            before[name] = field_to_text(note[name])

        fd, path = tempfile.mkstemp(prefix="clanki-", suffix=".md")
        with os.fdopen(fd, "w") as f:
            f.write(note_to_file(note, self._deck_name))
        try:
            mtime = os.path.getmtime(path)
            run_editor(self.app, path)
            if os.path.getmtime(path) == mtime:
                log_edit("file not saved -> cancelled")
                self.notify("Edit cancelled", severity="information")
                return
            with open(path) as f:
                after = file_to_fields(f.read(), names)
        finally:
            os.unlink(path)

        changed = False
        for name in after:
            if after[name] != before[name].strip("\n"):
                note[name] = text_to_field(after[name])
                changed = True
        if not changed:
            log_edit("saved, but no field changed")
            self.notify("No changes", severity="information")
            return

        try:
            col.update_note(note)
            # remember how anki names this undo step (it's translated),
            # u checks it to know an edit is on top of the stack
            self._edit_label = col.undo_status().undo
            rerender(self)
            log_edit("note updated")
            self.notify("Card edited (u undoes it)", severity="information")
        except Exception as exc:
            self.notify(f"Edit failed: {exc}", severity="error")

    old_undo = ReviewScreen.action_undo

    async def undo_with_edits(self):
        col = self.clanki_app.state.col
        label = getattr(self, "_edit_label", None)
        if col is not None and label and col.undo_status().undo == label:
            try:
                col.undo()
                rerender(self)
                self.notify("Edit undone", severity="information")
            except Exception as exc:
                self.notify(f"Undo failed: {exc}", severity="warning")
            return
        await old_undo(self)

    edit_old_init = ReviewScreen.__init__
    edit_old_help = ReviewScreen._get_help_text

    def edit_init(self, *args, **kwargs):
        edit_old_init(self, *args, **kwargs)
        self._bindings.bind("e", "edit_card", "Edit", show=False)

    def edit_help(self):
        text = edit_old_help(self)
        text = text.replace("[dim]s[/dim] snd:", "[dim]e[/dim] edit  [dim]s[/dim] snd:", 1)
        text = text.replace("[dim]b[/dim] bury", "[dim]e[/dim] edit  [dim]b[/dim] bury", 1)
        return text

    ReviewScreen.action_edit_card = action_edit_card
    ReviewScreen.action_undo = undo_with_edits
    ReviewScreen.__init__ = edit_init
    ReviewScreen._get_help_text = edit_help
except Exception as e:
    print(f"edit card skipped: {e}", file=sys.stderr)

# 6. answer side keeps the front of the card
# anki puts the front on the back through {{FrontSide}}<hr id=answer>, clanki
# cuts everything before that line and shows only the back - here it stays,
# so it looks like in anki desktop: front, a line, back
# (clanki's own <hr> line ends up glued to the text, so it's swapped for <br>s)
# (cards whose template has no {{FrontSide}}, like cloze, don't change)
try:
    import clanki.render.html as clanki_html

    def keep_front_side(html):
        return clanki_html._HR_ID_ANSWER_PATTERN.sub("<br>" + "─" * 30 + "<br>", html)

    clanki_html._strip_front_side_from_answer = keep_front_side
except Exception as e:
    print(f"keep front side skipped: {e}", file=sys.stderr)

from clanki.cli import main

sys.exit(main())
