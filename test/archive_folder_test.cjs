const {test} = require('node:test');
const assert = require('node:assert/strict');
const resolve = require('../web/archive_folder.js');
function selected(name, marker = false, child = {name: 'Diario dei sogni'}) {
  return {
    name, created: 0,
    async getFileHandle() {
      if (marker) return {};
      throw Object.assign(new Error('Not found'), {name: 'NotFoundError'});
    },
    async getDirectoryHandle(name, options) { assert.equal(name, 'Diario dei sogni'); assert.equal(options.create, true); this.created++; return child; },
  };
}
test('selecting the archive itself never creates an empty nested folder', async () => {
  const root = selected('Diario dei sogni');
  assert.equal(await resolve(root), root); assert.equal(root.created, 0);
});
test('an archive with a renamed folder is recognized by its marker', async () => {
  const root = selected('I miei sogni', true);
  assert.equal(await resolve(root), root); assert.equal(root.created, 0);
});
test('selecting the container opens its archive child', async () => {
  const child = {name: 'Diario dei sogni'};
  const root = selected('Drive', false, child);
  assert.equal(await resolve(root), child); assert.equal(root.created, 1);
});
test('existing parent archive wins over an accidental nested empty archive', async () => {
  const root = selected('Archivio', true, {name: 'Diario dei sogni'});
  assert.equal(await resolve(root), root); assert.equal(root.created, 0);
});
test('permission or cloud read failures are reported without creating a new archive', async () => {
  const root = selected('Drive');
  root.getFileHandle = async () => { throw Object.assign(new Error('Denied'), {name: 'NotAllowedError'}); };
  await assert.rejects(resolve(root), {name: 'NotAllowedError'}); assert.equal(root.created, 0);
});
