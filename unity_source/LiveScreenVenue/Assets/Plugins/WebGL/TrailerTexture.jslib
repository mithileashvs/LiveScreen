// Streams a plain HTML5 <video> element's decoded frames into Unity WebGL,
// for the ONLY trailer case this architecture can actually put onto the
// generated 3D cinema screen: a direct video file (.mp4/.webm/...).
//
// WHY THIS EXISTS AND WHAT IT CANNOT DO
//
// A browser gives JavaScript pixel-level access to a <video> element's
// decoded frames via <canvas>.drawImage() + getImageData() — but ONLY
// when the video's own host allows it. Cross-origin video without
// Access-Control-Allow-Origin taints the canvas the moment you draw a
// frame from it, and getImageData() throws from then on. That is a
// browser security restriction, not a bug in this file — see
// TrailerTexture_GetFrame below, which reports that failure back to C#
// rather than pretending it worked.
//
// There is NO equivalent path for a YouTube/Vimeo <iframe>: an iframe's
// rendered pixels are never exposed to the embedding page through any
// browser API, CORS or not. That is why TrailerScreenPlayer.cs never
// calls into this file for those providers — see its class doc.
mergeInto(LibraryManager.library, {

  // Creates (or replaces) a hidden <video> element playing [url], and a
  // same-sized offscreen <canvas> used to read its frames back out.
  TrailerTexture_Load: function (idPtr, urlPtr) {
    var id = UTF8ToString(idPtr);
    var url = UTF8ToString(urlPtr);

    if (!window.__trailerVideos) window.__trailerVideos = {};
    if (!window.__trailerCanvases) window.__trailerCanvases = {};

    var existing = window.__trailerVideos[id];
    if (existing) {
      existing.pause();
      existing.src = '';
      existing.load();
      existing.remove();
    }

    var video = document.createElement('video');
    // Required for getImageData() to succeed on ANY frame, but is not
    // sufficient by itself — the host must also send an
    // Access-Control-Allow-Origin header permitting this page's origin.
    video.crossOrigin = 'anonymous';
    // Autoplay in a browser generally requires the element be muted.
    // The trailer's own audio track is intentionally not what carries
    // sound here — see TrailerScreenPlayer.cs's class doc for the
    // current audio story (the theatre's spatial speakers, not this
    // element, are the "real" audio path; decoding this element's own
    // audio track through them is a documented gap, not implemented).
    video.muted = true;
    video.autoplay = true;
    video.loop = true;
    video.playsInline = true;
    video.src = url;
    video.style.display = 'none';
    document.body.appendChild(video);

    var canvas = document.createElement('canvas');
    var ctx = canvas.getContext('2d', { willReadFrequently: true });

    window.__trailerVideos[id] = video;
    window.__trailerCanvases[id] = { canvas: canvas, ctx: ctx };

    video.play().catch(function (err) {
      // Most commonly an autoplay-policy rejection or a genuine load
      // failure (404, unsupported codec). Recorded on the element itself
      // so TrailerTexture_HasError can see it without a second channel.
      video.dataset.playError = String(err);
    });
  },

  TrailerTexture_IsReady: function (idPtr) {
    var id = UTF8ToString(idPtr);
    var video = window.__trailerVideos && window.__trailerVideos[id];
    // readyState >= 2 (HAVE_CURRENT_DATA) means at least one decoded
    // frame exists to read.
    return (video && video.readyState >= 2 && video.videoWidth > 0) ? 1 : 0;
  },

  TrailerTexture_HasError: function (idPtr) {
    var id = UTF8ToString(idPtr);
    var video = window.__trailerVideos && window.__trailerVideos[id];
    if (!video) return 1;
    return (video.error || video.dataset.playError || video.dataset.drawError) ? 1 : 0;
  },

  TrailerTexture_GetWidth: function (idPtr) {
    var id = UTF8ToString(idPtr);
    var video = window.__trailerVideos && window.__trailerVideos[id];
    return video ? video.videoWidth : 0;
  },

  TrailerTexture_GetHeight: function (idPtr) {
    var id = UTF8ToString(idPtr);
    var video = window.__trailerVideos && window.__trailerVideos[id];
    return video ? video.videoHeight : 0;
  },

  // Draws the video's CURRENT frame and writes it into Unity's heap at
  // [bufferPtr] as tightly-packed RGBA8 bytes (top-left origin, same as
  // Texture2D.LoadRawTextureData expects when the caller flips it — see
  // TrailerScreenPlayer.cs). Returns the number of bytes written, or 0 if
  // the frame could not be captured (not yet ready, or a tainted-canvas
  // security error — see the file header).
  TrailerTexture_GetFrame: function (idPtr, bufferPtr, bufferLen) {
    var id = UTF8ToString(idPtr);
    var video = window.__trailerVideos && window.__trailerVideos[id];
    var entry = window.__trailerCanvases && window.__trailerCanvases[id];
    if (!video || !entry || video.videoWidth === 0) return 0;

    if (entry.canvas.width !== video.videoWidth || entry.canvas.height !== video.videoHeight) {
      entry.canvas.width = video.videoWidth;
      entry.canvas.height = video.videoHeight;
    }

    try {
      entry.ctx.drawImage(video, 0, 0, entry.canvas.width, entry.canvas.height);
      var frame = entry.ctx.getImageData(0, 0, entry.canvas.width, entry.canvas.height);
      var needed = frame.data.length;
      if (needed > bufferLen) return 0; // caller's buffer is undersized for this frame
      HEAPU8.set(frame.data, bufferPtr);
      return needed;
    } catch (e) {
      // Cross-origin (tainted canvas) is by far the most likely cause —
      // see the file header. Recorded so TrailerTexture_HasError picks it
      // up as a permanent failure rather than this being retried forever.
      video.dataset.drawError = String(e);
      return 0;
    }
  },

  TrailerTexture_Unload: function (idPtr) {
    var id = UTF8ToString(idPtr);
    var video = window.__trailerVideos && window.__trailerVideos[id];
    if (video) {
      video.pause();
      video.src = '';
      video.load();
      video.remove();
      delete window.__trailerVideos[id];
    }
    if (window.__trailerCanvases) delete window.__trailerCanvases[id];
  }
});
