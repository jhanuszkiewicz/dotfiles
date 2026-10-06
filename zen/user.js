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
