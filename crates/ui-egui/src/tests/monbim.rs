//! MonBIM's own: its name and year in the window, About, and the credit to BIMCraft it is based on.

use super::*;
use crate::brand;

#[test]
fn the_window_title_and_the_start_page_say_monbim_and_its_year() {
    let mut h = app(BOX);
    h.run();
    assert!(h.state().title.ends_with(" · MonBIM 2026"), "{}", h.state().title);
    assert_eq!(brand::FULL_NAME, "MonBIM 2026");
    h.state_mut().show_start_page();
    h.run();
    assert!(h.query_all_by_label(brand::FULL_NAME).next().is_some(), "the start page's name");
    assert!(h.query_by_label("BIMCraft").is_none(), "upstream's name is not the product's");
    h.get_by_label("Based on BIMCraft");
    h.get_by_label("MonBIM source code");
    h.get_by_label("Source code on GitHub");
    // Its footer opens About.
    press(&mut h, "About MonBIM");
    assert!(h.state().about);
    key(&mut h, Key::Escape);
    assert!(!h.state().about, "Esc closes it");
}

#[test]
fn file_help_about_says_what_monbim_is_and_what_it_is_based_on() {
    let mut h = app(BOX);
    file_menu(&mut h, "Help", "About MonBIM…");
    assert!(h.state().about);
    assert!(h.query_all_by_label("MonBIM 2026").next().is_some());
    h.get_by_label(&format!("Version {}", env!("CARGO_PKG_VERSION")));
    h.get_by_label("Based on BIMCraft");
    h.get_by_label("MonBIM source code");
    h.get_by_label("Not affiliated with or endorsed by BIMCraft's authors.");
    // A dialog holds the window's keys while it is up.
    let ctx = h.ctx.clone();
    assert!(h.state().keys_taken(&ctx));
    let close = h.get_all_by_label("Close").last().map(|n| n.rect().center()).expect("a Close button");
    click_at(&mut h, close);
    assert!(!h.state().about, "Close closes it");
    assert!(!h.state().keys_taken(&ctx));
}

#[test]
fn the_profiles_name_is_monbim_and_its_saved_code_is_upstreams() {
    use crate::style::Profile;
    assert_eq!(Profile::BimCraft.name(), "MonBIM");
    assert_eq!(Profile::from_code("bimcraft"), Some(Profile::BimCraft), "settings an upstream build wrote still read");
}

#[test]
fn an_updater_that_does_not_look_by_itself_asks_only_when_told_and_says_when_it_could_not() {
    use bimcraft_update::testing::Fake;
    use bimcraft_update::{LATEST_URL, Updater, Version};
    let net = Arc::new(Fake::default().fail(LATEST_URL, "404 Not Found"));
    let mut h = app(BOX);
    h.state_mut().updates = Some(Updater::new(net.clone(), Version::new(0, 4, 0), None, || {}).inline().automatic(false));
    if let Some(updates) = h.state_mut().updates.as_mut() {
        updates.check_at_startup();
    }
    h.run();
    assert!(net.asked().is_empty(), "no request at startup");
    press(&mut h, "File");
    assert!(h.query_by_label("Check for updates at startup").is_none(), "no switch for a check that never comes");
    press(&mut h, "Check for Updates Now");
    assert_eq!(net.asked().len(), 1);
    let status = h.state().status.clone();
    assert!(status.error && status.text.starts_with("Couldn't check for updates:"), "{status:?}");
}

#[test]
fn the_window_speaks_mongolian_keeps_to_it_and_starts_projects_in_english() {
    use crate::lang::{Lang, translated_in};
    use crate::settings::language_in;
    let dir = tempfile::tempdir().unwrap();
    let file = dir.path().join("settings.json");
    let mut h = app(BOX);
    h.state_mut().use_settings(file.clone());
    let ctx = h.ctx.clone();
    h.state_mut().set_lang(&ctx, Lang::Mongolian);
    h.run();
    assert_eq!(h.state().lang, Lang::Mongolian, "no font to look for: the window's own have Cyrillic");
    assert_eq!(language_in(&file), Some(Lang::Mongolian), "kept in the settings file as `mn`");
    let again = {
        let mut h = app(BOX);
        h.state_mut().use_settings(file.clone());
        h.run();
        h.state().lang
    };
    assert_eq!(again, Lang::Mongolian, "a window started later is in it too");
    // The words go through mn.po, English where it has none yet; a new project is named in English.
    let word = |english: &'static str| translated_in(Lang::Mongolian, english).unwrap_or(english);
    let n = cmd_n(&h);
    press(&mut h, word("File"));
    press(&mut h, &format!("{} ⏵", word("New")));
    press(&mut h, &format!("{} {n}", word("Project")));
    let levels: Vec<String> = h.state().session.model.levels().iter().map(|(_, l)| l.name.clone()).collect();
    assert_eq!(levels, ["Level 1", "Level 2"]);
}
