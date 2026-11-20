// What the sidebar's rail draws: space tiles, agent tiles, their status marks
// and the captions over them. Only the spaces mod draws the rail.

import { div, image, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { run } from "herdr";

// Rows are 36px apart and hold a 30px tile, both on the rail's center line.
export const ROW = 36;
// Agent rows are as far apart as space rows: an agent's number is on the
// corner across from the status mark, so neighbors' marks never meet.
export const AGENT_ROW = 36;
const TILE = 30;
// The hover plate around a tile. Corner marks are placed from its top-left.
const BOX = 36;
const INSET = (BOX - TILE) / 2;

// The status mark sits on the tile's bottom-right corner, on a disc of the
// rail's own color that leaves a 1.5px gap around it. It is the same in both
// lists, by one rule, and never moves what is in the tile's middle: an agent's
// tile shows that agent's state, a space's tile the state of its most urgent
// agent. Only states worth a look get a mark, loudest first: blocked a red disc
// with a "!"; done a blue disc with a tick; working a yellow arc that spins.
// Idle and "no agents" have no mark, so a resting rail stays quiet; the
// tooltip still says which.
const MARKS = {
  blocked: (t) => svg("mods/spaces-mine/alert.svg").size(11).flex_none().text_color(t.blocked),
  done: (t) => h_flex().size(11).flex_none().rounded(5.5).bg(t.done).items_center().justify_center()
    .child(svg("mods/spaces-mine/tick.svg").size(7).flex_none().text_color(t.chrome)),
  working: (t) => svg("mods/spaces-mine/working.svg").size(11).flex_none().text_color(t.working).spin(1400),
};
const DISC = { blocked: 14, done: 14, working: 14 };
// Where every mark's middle is, from the hover plate's top-left.
const CORNER = INSET + TILE - 4;
function badge(t, status) {
  const disc = DISC[status];
  return disc && h_flex().absolute().left(CORNER - disc / 2).top(CORNER - disc / 2).size(disc).rounded(disc / 2).bg(t.chrome).items_center().justify_center().child(MARKS[status](t));
}

// A space is its number, in the text color when it is the one on screen and
// muted otherwise. Tiles have no fill at rest, so the rail reads as a column of
// numbers; hovering fills the plate behind one. The one on screen gets the
// tile fill with a wash of the accent, under the ring railRow draws. A
// worktree's tile is an outline.
export function spaceTile(t, n, { outlined, on }) {
  return h_flex().relative().size(TILE).flex_none().rounded(8).items_center().justify_center()
    .when(!outlined && Boolean(on), (el) => el.bg(t.raised))
    .when(Boolean(outlined), (el) => el.border(1.5).border_color(t.dim))
    .when(Boolean(on), (el) => el.child(div().absolute().left(0).top(0).size(TILE).rounded(8).bg(t.accent + "2e")))
    .child(div().text_size(13).font_bold().text_color(on ? t.foreground : t.muted).child(String(n)));
}

// An agent is its program's icon where a space has its number, so the agents
// never read as more spaces. Like a space, it has no fill unless it is the one
// on screen.
export function agentTile(t, program, on) {
  const pic = !program?.icon ? svg("mods/spaces-mine/bot.svg").size(16).flex_none().text_color(t.foreground)
    : program.tint ? svg(program.icon).size(16).flex_none().text_color(t.foreground)
    : image(program.icon).w(16).h(16).flex_none();
  return h_flex().size(TILE).flex_none().rounded(8).when(Boolean(on), (el) => el.bg(t.raised)).items_center().justify_center().child(pic);
}
// The number of the agent's space: a miniature space tile on the tile's
// top-left corner, across from the status mark. Every agent has the same one,
// a small rounded square a shade lighter than the tiles with the number in it, so it reads as "in space N"
// and not as a count of something unread. It starts on the tile's left edge
// and two digits grow inward, so both lists keep their edges. Like the status
// mark, it sits on a notch of the rail's color.
// `on`: the agent on screen. Only the chip's fill changes, to the accent with
// a dark digit, so the accent ring runs into it as one closed outline.
const CHIP = 12;
const NOTCH = 1.5;
function spaceMark(t, n, on) {
  return h_flex().absolute().left(INSET - NOTCH - 1).top(0).p(NOTCH).rounded(4 + NOTCH).bg(t.chrome)
    .child(h_flex().h(CHIP).min_w(CHIP).px(2).rounded(4).items_center().justify_center()
      .bg(on ? t.accent : t.foreground + "29")
      .text_size(9).font_bold().text_color(on ? t.chrome : t.foreground + "cc").child(String(n)));
}

// One row: a tile, marked when it is the one on screen. Both lists use an
// accent ring on the tile's own edge, inside its 30px, so the tile is no
// bigger than its neighbors. The space on screen is the main mark: a 2px
// square ring over an accent-washed fill. The agent on screen is the lesser
// one: a thinner 1.5px ring on the plain fill, and its number chip in the accent.
// `on`: "space" or "agent". `corner`: an extra mark over the tile. `h`: the
// row's height.
export function railRow(t, { id, tile, status, on, tooltip, corner, h = ROW }) {
  const mark = badge(t, status);
  // The rings are their own layers, so a row is laid out the same with or without them.
  const ring = div().absolute().left(INSET).top(INSET).size(TILE).rounded(8).border(2).border_color(t.accent);
  const thin = div().absolute().left(INSET).top(INSET).size(TILE).rounded(8).border(1.5).border_color(t.accent);
  return h_flex().id(id).h(h).w_full().flex_none().items_center().justify_center().cursor_pointer().tooltip(tooltip)
    .child(h_flex().id(`${id}-box`).relative().size(BOX).flex_none().items_center().justify_center().rounded(11)
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .child(tile)
      .when(on === "agent", (el) => el.child(thin))
      .when(on === "space", (el) => el.child(ring))
      .when(Boolean(corner), (el) => el.child(corner))
      .when(Boolean(mark), (el) => el.child(mark)));
}

const says = (name, status) => (status ? `${name} · ${status}` : name);
// A space's tooltip says what its mark means, and what no mark means.
const spaceSays = (name, status) => `${name} · ${status ? `agent ${status}` : "no agents"}`;

export function spaceRow(t, { w, n, outlined }) {
  return railRow(t, { id: `space-${w.id}`, tile: spaceTile(t, n, { outlined, on: w.active }), status: w.status, on: w.active ? "space" : null, tooltip: spaceSays(w.name, w.status) });
}

// `n`: the number of the agent's space, 0 when it isn't listed.
export function agentRow(t, a, n, tip) {
  return railRow(t, { id: `ag-${a.address}`, tile: agentTile(t, a.program, a.focused), corner: n ? spaceMark(t, n, a.focused) : null, status: a.status, on: a.focused ? "agent" : null, tooltip: says(tip || "Agent", a.status), h: AGENT_ROW })
    .on_click(() => run("pane.focus", { pane: a.pane }));
}

// New space, after the last one: a bare plus, smaller than a tile, so it never
// counts as one more space. It sits as far under the last tile as the tiles
// sit from each other, and stays put under the list when the list scrolls.
export const ADD_ROW = 24;
export function addRow(t) {
  return h_flex().id("space-new").h(ADD_ROW).w_full().flex_none().items_center().justify_center().cursor_pointer().tooltip("New space")
    .child(h_flex().id("space-new-tile").size(22).flex_none().rounded(7).items_center().justify_center()
      .text_color(t.dim).hover((s) => s.bg(t.hover).text_color(t.foreground))
      .child(svg("mods/workspace-chrome/plus.svg").size(14).flex_none()));
}

// A section (spaces, agents) starts with a divider across the rail, like the
// one over the settings gear, and a small glyph. The glyph has no hover and no
// pointer: it is the section's title, not a button.
// `gap`: the room above the divider, for a section that follows another.
export const SECTION_HEAD = 26;
export const SECTION_GAP = 4;
export function sectionHead(t, { id, icon, tooltip, gap = 0 }) {
  return [
    div().h(1).mt(gap).flex_none().bg(t.border),
    h_flex().id(id).h(SECTION_HEAD - 1).pt(4).flex_none().items_center().justify_center().tooltip(tooltip)
      .child(svg(icon).size(12).flex_none().text_color(t.foreground + "8c")),
  ];
}
export const spacesHead = (t) => sectionHead(t, { id: "spaces-head", icon: "mods/workspace-chrome/layers.svg", tooltip: "Spaces" });
export const agentsHead = (t) => sectionHead(t, { id: "agents-head", icon: "mods/spaces-mine/bot.svg", tooltip: "Agents", gap: SECTION_GAP });

// A machine above its spaces: its name's first three letters in small capitals,
// no fill and no icon, as wide as a tile at most. The full name is in the
// tooltip. A group after another starts with a short rule and more room
// (MACHINE_GAP) than there is between tiles, so the name reads as a caption
// that starts a group, not a row in it. The first group sits right under the
// section's glyph (MACHINE_FIRST): the full-width divider over the glyph
// already starts it, and short rules only ever part two machines.
export const MACHINE_LABEL = 16;
export const MACHINE_GAP = 12;
export const MACHINE_FIRST = 2;
export function machineLabel(t, id, text) {
  return h_flex().id(id).w(BOX).h(MACHINE_LABEL).flex_none().overflow_hidden().items_center().justify_center()
    .text_size(10).font_semibold().text_color(t.foreground + "b3").hover((s) => s.text_color(t.foreground))
    .child(text);
}
// The short rule between two machines' groups.
export const machineRule = (t) => h_flex().h(MACHINE_GAP).w_full().flex_none().items_center().justify_center().child(div().w(14).h(1).bg(t.input));
export const machineLead = () => div().h(MACHINE_FIRST).flex_none();
