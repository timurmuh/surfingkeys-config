/// <reference types="./output" />

// Test TypeScript definitions with example Surfingkeys configuration

// Test mapkey
api.mapkey('<Space>f', 'Open link in hints', function () {
    api.Hints.create('a', api.Hints.dispatchMouseClick);
});

// Test RUNTIME
api.RUNTIME('getTabs', { queryInfo: { active: true } }, function (tabs) {
    console.log('Active tab:', tabs[0].url);
});

// Test Clipboard
api.Clipboard.read(function (response) {
    console.log('Clipboard contents:', response.data);
});

api.Clipboard.write('Test content');

// Test vmapkey (visual mode)
api.vmapkey('y', 'Yank text', function () {
    api.Clipboard.write(window.getSelection().toString());
});

// Test imapkey (insert mode)
api.imapkey('<Ctrl-e>', 'Edit input', function () {
    console.log('Edit mode');
});

// Test mapkey with autocomplete
api.mapkey('<Space>f', 'Open link', function () {
    api.Hints.create('a', api.Hints.dispatchMouseClick);
});

// Test vmapkey
api.vmapkey('y', 'Yank text', function () {
    api.Clipboard.write(window.getSelection().toString());
});

// Test imapkey
api.imapkey('<Ctrl-e>', 'Edit', function () {
    console.log('Edit mode');
});

// Test RUNTIME
api.RUNTIME('getTabs', { queryInfo: { active: true } }, function (tabs) {
    console.log(tabs);
});

// Test Clipboard
api.Clipboard.read(function (response) {
    console.log(response.data);
});

// Test Front
api.Front.showBanner('Hello!', 2000);
api.Front.showPopup('Popup message');

// Test Normal
api.Normal.feedkeys('gg');
api.Normal.scroll('top');

// Test Visual
api.Visual.style('marks', 'color: red;');

// Test Hints
api.Hints.create('a', api.Hints.dispatchMouseClick);
api.Hints.style('border: solid 1px red;');
