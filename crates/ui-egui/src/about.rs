//! MonBIM's own: File > Help (About, and the news and the account once they are attached) and the About window, which says
//! what MonBIM is, which version, and what it is based on: BIMCraft, credited in plain text with links to both repositories.

use egui::{Context, Id, RichText, Ui};

use crate::BimApp;
use crate::brand;
use crate::lang::{t, tf};
use crate::popup::Modal;
use crate::style::pal;

impl BimApp {
    /// File > Help: About MonBIM, the one item a window always has.
    pub(crate) fn help_menu(&mut self, ui: &mut Ui) {
        egui::containers::menu::SubMenuButton::new(t("Help")).ui(ui, |ui| {
            if ui.button(tf("About {}…", &[brand::NAME])).clicked() {
                self.about = true;
            }
        });
    }

    /// The About window, while it is open.
    pub(crate) fn about_window(&mut self, ctx: &Context) {
        if !self.about {
            return;
        }
        let mut close = false;
        let title = tf("About {}", &[brand::NAME]);
        let r = Modal::new(Id::new("about-monbim"), title).width(460.0).show(ctx, |ui| {
            crate::popup::body(ui, |ui| {
                ui.add_space(6.0);
                ui.label(RichText::new(brand::FULL_NAME).size(26.0).strong().color(pal().text));
                ui.label(RichText::new(tf("Version {}", &[env!("CARGO_PKG_VERSION")])).color(pal().muted));
                ui.add_space(8.0);
                ui.label(t("Building information modelling, open and free."));
                ui.add_space(10.0);
                credit(ui);
                ui.add_space(10.0);
                let muted = |ui: &mut Ui, text: &str| ui.label(RichText::new(text).small().color(pal().muted));
                muted(ui, t("MIT OR Apache-2.0; builds that read Revit files are Apache-2.0."));
                muted(ui, t("Not affiliated with or endorsed by BIMCraft's authors."));
            });
            crate::popup::footer(ui, |ui| {
                close = ui.button(t("Close")).clicked();
            });
        });
        if close || r.should_close() {
            self.about = false;
        }
    }
}

/// The credit the start page and About share: based on BIMCraft (its repository), and MonBIM's own source code.
pub(crate) fn credit(ui: &mut Ui) {
    ui.horizontal_wrapped(|ui| {
        ui.hyperlink_to(t("Based on BIMCraft"), brand::UPSTREAM).on_hover_text(brand::UPSTREAM_LABEL);
        ui.label(RichText::new("·").color(pal().muted));
        ui.hyperlink_to(tf("{} source code", &[brand::NAME]), brand::SOURCE).on_hover_text(brand::SOURCE_LABEL);
    });
}
