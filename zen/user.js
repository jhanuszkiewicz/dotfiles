// ustawienia zena, ladowane przy kazdym starcie

// bez tego zen ignoruje userChrome.css i userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// strony w trybie ciemnym
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// pusta nowa karta bez skrotow, reklam i newsow
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// bez animacji przy pelnym ekranie
user_pref("browser.fullscreen.animate", false);

// default page background while a page is still loading (kills the white flash)
// hswi rewrites the color from zen/chrome/colors.css (--dot-bg) on every switch
// if some page shows dark text on dark bg, remove these two lines
user_pref("browser.display.background_color", "#1e1e2e");
user_pref("browser.display.background_color.dark", "#1e1e2e");

// one font on every page instead of what the site picks (hswi rewrites the
// name from --dot-font in zen/chrome/colors.css)
// icons still work: icon fonts (font awesome, material icons) are allowed anyway
// to give pages their own fonts back set this to 1
user_pref("browser.display.use_document_fonts", 0);
user_pref("font.name.sans-serif.x-western", "Departure Mono");
user_pref("font.name.serif.x-western", "Departure Mono");
user_pref("font.name.monospace.x-western", "Departure Mono");
user_pref("font.name.sans-serif.x-unicode", "Departure Mono");
user_pref("font.name.serif.x-unicode", "Departure Mono");
user_pref("font.name.monospace.x-unicode", "Departure Mono");
