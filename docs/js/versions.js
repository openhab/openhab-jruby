/**
 * This script populates the archived versions dropdown in the documentation.
 * Place this in the root /js/ directory outside of the versioned directories.
 */

function populateArchivedVersions() {
  const archivedVersions = [
    "5.0",
    "5.1",
    "5.2",
    "5.3",
    "5.4",
    "5.5",
    "5.6",
    "5.7",
    "5.8",
    "5.9",
    "5.10",
    "5.11",
    "5.12",
    "5.15",
    "5.17",
    "5.18",
    "5.19",
    "5.20",
    "5.21",
    "5.22",
    "5.23",
    "5.24",
    "5.25",
    "5.26",
    "5.27",
    "5.28",
    "5.29",
    "5.30",
    "5.31",
    "5.32",
    "5.33",
    "5.34",
    "5.35",
    "5.36",
    "5.37",
  ]; // ARCHIVED_VERSIONS_MARKER
  const versionDropdown = $("#version-dropdown");
  archivedVersions.forEach((version) => {
    const versionLink = $("<a>")
      .attr("href", `/openhab-jruby/${version}/`)
      .text(version);
    const listItem = $("<li>")
      .addClass("dropdown-item")
      .append(versionLink);
    versionDropdown.append(listItem);
  });
}

$(document).ready(function() {
  populateArchivedVersions();
});