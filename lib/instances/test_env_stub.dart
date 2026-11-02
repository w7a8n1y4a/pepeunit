/// Web build: no dart:io, so the runner state is unknown and isolate offload
/// stays enabled where it is real work (`compute` runs inline on web).
bool get inFlutterTestRunner => false;
