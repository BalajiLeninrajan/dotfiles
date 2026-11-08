// Collapses the sidebar to its icon rail or expands it back, like the sidebar
// button in workspace-chrome, which keys can't reach. Opened as an overlay by
// a key; it toggles once and closes itself.
import { View, div } from "gpui-kit";
import { closeOverlay, layout, props, run, setShared, shared, window } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The shipped mods treat any sidebar under 160px as the rail.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

function toggleSidebar() {
  const sidebar = find(layout(), "sidebar");
  if (!sidebar) return;
  // A hidden sidebar just comes back.
  if (sidebar.hidden) return run("layout.show", { id: "sidebar" });
  const wasNarrow = narrow();
  if (!wasNarrow) setShared("sidebar.width", sidebar.size?.px);
  // Mods edited before the rail went by width still read the flag.
  setShared("sidebar.collapsed", !wasNarrow);
  run("layout.resize", { id: "sidebar", px: wasNarrow ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
}

export default class SidebarToggle extends View {
  init() {
    // Only as the overlay a key opens; `herdr-app check` loads it without one.
    const overlay = props()?.overlay;
    if (!overlay) return;
    toggleSidebar();
    closeOverlay(overlay);
  }

  render() {
    return div();
  }
}
