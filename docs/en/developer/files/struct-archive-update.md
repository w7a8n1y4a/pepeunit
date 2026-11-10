# Update archive structure

Pepeunit builds ready-made update archives for Units. The algorithm differs for compiled and interpreted Units.

The archive can be obtained in tgz, tar and zip formats: through the [MQTT command UPDATE](/developer/mqtt/default-mqtt-command#update-updatepepeunit) and REST, or in the client: `Units` → Unit → `Manage unit` → `Program archives`.

## Compiled

The archive contains only the configuration, the program itself is downloaded separately, [details](/developer/release-assets).

1. The [target version](/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) is calculated
1. env.json and schema.json for this version are added
1. The target version is written to env.json: PU_COMMIT_VERSION
1. The archive is created

## Interpreted

The steps are the same, but after calculating the target version and before adding env.json and schema.json:
1. A temporary copy of the files of this commit is created
1. Files that are not needed for the Unit to work are deleted according to [.pepeignore](/developer/files/struct-pepeignore)
