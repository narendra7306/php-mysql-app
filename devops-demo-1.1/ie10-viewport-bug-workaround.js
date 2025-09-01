(function () {
  'use strict';

  if (/IEMobile\/10\.0/.exec(navigator.userAgent)) {
    const msViewportStyle = document.createElement('style');
    msViewportStyle.appendChild(
      document.createTextNode(
        '@-ms-viewport{width:auto!important}'
      )
    );
    document.querySelector('head').appendChild(msViewportStyle);
  }

})();
