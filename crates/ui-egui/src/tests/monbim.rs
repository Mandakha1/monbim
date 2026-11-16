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
