// This file lives inside the compiled Unity WebGL build and lets C# code
// call out to JavaScript, which then forwards a message to whatever page
// is hosting this Unity instance (our Flutter web app, via an iframe).
mergeInto(LibraryManager.library, {
  SendMessageToFlutter: function (messagePtr) {
    var message = UTF8ToString(messagePtr);
    // Unity runs inside an <iframe>, so "window.parent" is the Flutter page
    // that embedded it. postMessage is the standard, safe way for an
    // iframe to talk to its parent page.
    if (window.parent) {
      window.parent.postMessage(message, "*");
    }
  }
});
