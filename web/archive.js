/* Directory permissions belong to the browser. No cloud password or audio is
   sent to this website. A cloud desktop client may synchronize this folder. */
(() => {
  let root = null;
  const valid = name => /^[a-zA-Z0-9_.-]{1,200}$/.test(name) && !name.includes('..');
  async function db() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('diario-sogni-folder', 1);
      request.onupgradeneeded = () => request.result.createObjectStore('settings');
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }
  async function setting(value, write = false) {
    const database = await db();
    try {
      return await new Promise((resolve, reject) => {
        const tx = database.transaction('settings', write ? 'readwrite' : 'readonly');
        const store = tx.objectStore('settings');
        const request = write ? (value ? store.put(value, 'folder') : store.delete('folder')) : store.get('folder');
        tx.oncomplete = () => resolve(request.result);
        tx.onerror = () => reject(tx.error);
        tx.onabort = () => reject(tx.error);
      });
    } finally { database.close(); }
  }
  async function folder() {
    if (!root) throw new Error('Scegli la cartella dell’archivio.');
    const options = {mode: 'readwrite'};
    if (await root.queryPermission(options) !== 'granted' &&
        await root.requestPermission(options) !== 'granted') throw new Error('Accesso alla cartella non consentito.');
    return window.dreamArchiveResolveFolder(root);
  }
  window.dreamArchive = {
    supported: window.isSecureContext && typeof window.showDirectoryPicker === 'function',
    async restore() {
      root = await setting();
      return root ? root.name : null;
    },
    async choose() {
      try {
        const selected = await window.showDirectoryPicker({mode: 'readwrite', id: 'dream-archive'});
        root = selected;
        await setting(root, true);
        return root.name;
      } catch (error) {
        if (error.name === 'AbortError') return null;
        throw error;
      }
    },
    async disconnect() { await setting(null, true); root = null; },
    async list() {
      const result = [];
      for await (const [name, handle] of (await folder()).entries()) {
        if (handle.kind === 'file' && valid(name)) result.push(name);
      }
      return result;
    },
    async read(name) {
      if (!valid(name)) throw new Error('Nome non valido');
      const file = await (await (await folder()).getFileHandle(name)).getFile();
      if (file.size > 100 * 1024 * 1024) throw new Error('File troppo grande (limite 100 MB).');
      return new Uint8Array(await file.arrayBuffer());
    },
    async write(name, bytes) {
      if (!valid(name)) throw new Error('Nome non valido');
      const handle = await (await folder()).getFileHandle(name, {create: true});
      const stream = await handle.createWritable();
      try { await stream.write(bytes); await stream.close(); }
      catch (error) { await stream.abort(); throw error; }
    },
    async remove(name) {
      if (!valid(name)) throw new Error('Nome non valido');
      try { await (await folder()).removeEntry(name); }
      catch (error) { if (error.name !== 'NotFoundError') throw error; }
    }
  };
})();
