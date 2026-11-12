import 'dart:js_interop';

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external bool get fullscreenEnabled;
  external _Element? get fullscreenElement;
  external _Element get documentElement;
  external JSPromise<JSAny?> exitFullscreen();
}

extension type _Element(JSObject _) implements JSObject {
  external JSPromise<JSAny?> requestFullscreen();
}

bool get fullscreenAvailable => _document.fullscreenEnabled;
bool get presentationIsFullscreen => _document.fullscreenElement != null;

Future<void> togglePresentationFullscreen() async {
  if (presentationIsFullscreen) {
    await exitPresentationFullscreen();
  } else {
    await _document.documentElement.requestFullscreen().toDart;
  }
}

Future<void> exitPresentationFullscreen() async {
  if (presentationIsFullscreen) await _document.exitFullscreen().toDart;
}
