//! MonBIM branding: the product name, its year, its links, and the id Windows shows its notifications under.
//!
//! MonBIM is based on BIMCraft (MIT OR Apache-2.0) by IPedrax and the BIMCraft contributors. BIMCraft's name is not licensed
//! for forks, so MonBIM uses its own name and credits BIMCraft in plain text only. Internal names stay upstream's (crates,
//! packages, `BIMCRAFT_*` variables) and so do the file formats (`.bimc`, `.bimf`, IFC's application name), which keep files
//! compatible with BIMCraft: see docs/monbim/FORK.md.

/// The product name shown to people, without the year: folders, messages, the MCP server.
pub const NAME: &str = "MonBIM";
/// The release year shown with the name. Next year change it and [`FULL_NAME`] (the installer reads both from here); folders
/// and executables stay without the year, so settings carry over.
pub const YEAR: &str = "2026";
/// What the window title, the start page, About and the installer show.
pub const FULL_NAME: &str = "MonBIM 2026";
/// The id Windows shows MonBIM's notifications under; the installer registers it.
pub const AUMID: &str = "MonHydro.MonBIM";

/// The project MonBIM is based on.
pub const UPSTREAM: &str = "https://github.com/IPedrax/BIMCraft";
pub const UPSTREAM_LABEL: &str = "github.com/IPedrax/BIMCraft";

/// MonBIM's source code.
pub const SOURCE: &str = "https://github.com/Mandakha1/monbim";
pub const SOURCE_LABEL: &str = "github.com/Mandakha1/monbim";

#[cfg(test)]
mod tests {
    #[test]
    fn the_full_name_is_the_name_and_the_year() {
        assert_eq!(super::FULL_NAME, format!("{} {}", super::NAME, super::YEAR));
    }

    #[test]
    fn the_links_are_the_upstream_and_monbims_own_repositories() {
        assert!(super::UPSTREAM.ends_with(super::UPSTREAM_LABEL) && super::SOURCE.ends_with(super::SOURCE_LABEL));
        assert_eq!(super::SOURCE, "https://github.com/Mandakha1/monbim");
    }
}
