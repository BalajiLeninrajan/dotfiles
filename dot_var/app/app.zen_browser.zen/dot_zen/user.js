// Zen reads this at startup and copies each pref into prefs.js.

// Let low-memory tab unloading drop tabs idle for 3 minutes, down from 10.
user_pref("browser.tabs.min_inactive_duration_before_unload", 180000);
