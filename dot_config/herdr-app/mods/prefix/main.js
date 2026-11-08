// Ctrl+F, then a key: the herdr TUI's prefix bindings (~/.config/herdr/config.toml).
// Adapted from herdrdev/herdr-layout-examples tmux-prefix.
import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, closeOverlay, focused, hc, nextCommand, props, run, theme } from "herdr";

const PREFIX = "ctrl+f";
const PREFIX_LABEL = "Ctrl+F";
// The hint stays invisible this long, so a quick prefix + key never flashes it.
const HINT_DELAY_MS = 500;

// Jump to the agent that wants you: blocked first, then finished, newest first.
function attention() {
  const rank = { blocked: 2, done: 1 };
  const next = agents()
    .filter((a) => rank[a.status])
    .sort((a, b) => rank[b.status] - rank[a.status] || b.seq - a.seq)[0];
  if (next) run("agent.focus", { terminal: next.address });
}

// [key, label, command or function, args]. Uppercase means shift.
const BINDINGS = [
  ["t", "New tab", "tab.new"],
  ["d", "Split down", "pane.split", { direction: "down" }],
  ["v", "Split right", "pane.split", { direction: "right" }],
  ["x", "Close pane", "pane.close"],
  ["z", "Zoom pane", "pane.zoom"],
  ["h", "Focus left", "pane.go", { direction: "left" }],
  ["j", "Focus down", "pane.go", { direction: "down" }],
  ["k", "Focus up", "pane.go", { direction: "up" }],
  ["l", "Focus right", "pane.go", { direction: "right" }],
  ["H", "Previous tab", "tab.prev", {}],
  ["L", "Next tab", "tab.next", {}],
  ["i", "Next space", "space.next", {}],
  ["o", "Previous space", "space.prev", {}],
  ["I", "Next agent", "agent.next", {}],
  ["O", "Previous agent", "agent.prev", {}],
  ["a", "Agent that needs you", attention],
  ["ctrl+h", "Swap left", "pane.swap", { direction: "left" }],
  ["ctrl+j", "Swap down", "pane.swap", { direction: "down" }],
  ["ctrl+k", "Swap up", "pane.swap", { direction: "up" }],
  ["ctrl+l", "Swap right", "pane.swap", { direction: "right" }],
  ["T", "Rename tab", "tab.rename"],
  ["X", "Close tab", "tab.close"],
  ["N", "New space", "space.new"],
  ["W", "Rename space", "space.rename"],
  ["D", "Close space", "space.close"],
  ["w", "Space picker", "mod.open", { name: "picker" }],
  ["b", "Collapse or expand sidebar", "mod.open", { name: "sidebar-toggle" }],
  ["s", "Settings", "app.settings"],
  ["q", "Close window, keep terminals", "window.close"],
  ["left", "Focus left", "pane.go", { direction: "left" }],
  ["down", "Focus down", "pane.go", { direction: "down" }],
  ["up", "Focus up", "pane.go", { direction: "up" }],
  ["right", "Focus right", "pane.go", { direction: "right" }],
  ...Array.from({ length: 9 }, (_, i) => [String(i + 1), `Tab ${i + 1}`, "tab.select", { index: i + 1 }]),
];

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.all = false;
    this.shown = false;
    cx.timer.after(HINT_DELAY_MS, (cx) => {
      this.shown = true;
      cx.notify();
    });
    // keys.json's mod:prefix section beats the global opener while this is open.
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  send(key, cx) {
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    // hc starts its subprocess at the call, before closing cancels this view's tasks.
    const pending = hc(["keys", terminal, key]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  sendPrefix(cx) {
    this.send(PREFIX, cx);
  }

  key(e, cx) {
    cx.stop_propagation();
    const m = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    if (`ctrl+${e.key}` === PREFIX && m.control && !m.alt) return this.sendPrefix(cx);
    const plain = !m.control && !m.alt && !m.platform;
    const ctrl = m.control && !m.alt && !m.platform && !m.shift;
    let key = null;
    if (plain) key = e.key_char ?? (m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key);
    else if (ctrl) key = `ctrl+${e.key}`;
    if (plain && key === "?") {
      this.shown = true;
      this.all = !this.all;
      cx.notify();
      return;
    }
    const binding = key && BINDINGS.find((b) => b[0] === key);
    this.dismiss();
    if (!binding) return;
    const [, , action, args = {}] = binding;
    if (typeof action === "function") action();
    else run(action, args);
  }

  render() {
    const t = theme();
    const rows = this.all ? BINDINGS : BINDINGS.filter(([key]) => !["left", "right", "up", "down"].includes(key) && !/^\d$/.test(key));
    // Keys work from the first frame; the hint only draws after the delay.
    // mod.json turns Herdr's frame off, so the frame is drawn here.
    const root = v_flex().id("prefix").size_full().track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx));
    if (!this.shown) return root;
    return root
      .bg(t.popover).border(1).border_color(t.border).rounded(10).shadow_lg()
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between().child(div().font_semibold().child(`${PREFIX_LABEL} · waiting for a key`))
        .child(div().text_color(t.muted).child(`Esc cancel · ${PREFIX_LABEL} send prefix`)))
      .child(v_flex().h(280).min_h(0).overflow_y_scrollbar().children(rows.map(([key, label]) =>
        h_flex().h(20).flex_none().items_center().gap(12).child(div().w(52).text_color(t.accent).child(key))
          .child(div().flex_1().child(label)))))
      .child(div().text_color(t.muted).child("1–9 tabs · arrows focus · ? all bindings"));
  }
}
