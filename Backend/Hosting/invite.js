'use strict';
// The bearer token stays in the URL fragment: no server request, analytics, or storage.
const token = location.hash.slice(1);
const valid = /^\/join\/?$/.test(location.pathname) && /^[a-fA-F0-9]{32}$/.test(token);
if (valid) {
  const open = document.getElementById('open');
  open.href = 'nanoom://join?code=' + token.toLowerCase();
  open.hidden = false;
} else {
  document.getElementById('description').textContent = 'A quiet place to share what’s on your heart and pray for one another.';
  document.getElementById('invalid').hidden = location.pathname === '/';
}
