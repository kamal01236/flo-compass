// Flo Compass HTML shell helpers (external file keeps nginx CSP strict).
(function () {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function (regs) {
      for (var i = 0; i < regs.length; i++) {
        var reg = regs[i];
        var url = reg.active && reg.active.scriptURL;
        if (url && url.indexOf('flutter_service_worker') !== -1) {
          reg.unregister();
        }
      }
    });
  }
  if ('caches' in window) {
    caches.keys().then(function (keys) {
      keys.forEach(function (key) {
        if (key.indexOf('flutter') === 0) {
          caches.delete(key);
        }
      });
    });
  }
})();

document.querySelector('.skip-link')?.addEventListener('click', function (event) {
  event.preventDefault();
  var target = document.getElementById('flutter-view');
  if (target) {
    target.setAttribute('tabindex', '-1');
    target.focus();
  }
});

window.addEventListener('flutter-first-frame', function () {
  var el = document.getElementById('flo-preloader');
  if (el) el.remove();
});
