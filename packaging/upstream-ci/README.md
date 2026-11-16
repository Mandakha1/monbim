# Upstream BIMCraft workflows (parked)

These are BIMCraft's own GitHub Actions workflows as of the fork (2026-11-16, upstream commit `a0c57b73`), moved here
unchanged so they no longer run in MonBIM's repository: `release.yml` publishes BIMCraft's MSI, AppImages, DMG, Flatpak and
APT repository (bimcraft.ipedrax.com) and needs BIMCraft's signing and key secrets, and `ci.yml` pushes to `IPedrax-Test/**`
branches. MonBIM's own CI is `.github/workflows/monbim.yml`. They are kept as the reference for porting steps (the IFC
validation with IfcOpenShell, the macOS and Linux packages, actionlint) into it. To run one again, move it back to
`.github/workflows/`.
