# UltraSource

UltraSource is the independent app catalog for UltraStore.

## Publish and add

The catalog and icon must reach the `develop` branch before this URL works:

https://raw.githubusercontent.com/glitchFling/SSUM/develop/UltraSource/source.json

Add that URL in the app's Sources screen. This starter catalog intentionally has no app listings yet.

## Add an app

Add an object to `apps` with `name`, `bundleIdentifier`, `developerName`, `localizedDescription`, `iconURL`, and a nonempty `versions` array. Each version needs `version`, `date` (ISO 8601), `downloadURL` (direct IPA URL), and `size` (bytes). Include `minOSVersion` and `sha256` when available.

Read the bundle identifier and version from the actual IPA. Use a public icon URL and a version-specific IPA URL so the download, size, and checksum stay consistent. List only apps you have permission to distribute.

The existing nightly workflow deploys source metadata to a separate SideStore catalog; it does not update UltraSource. Release automation has not been changed.
