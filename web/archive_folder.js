// Accept either the archive itself or its containing folder. Do not create
// a nested archive when an existing archive has been selected directly.
(function (scope) {
  async function resolveArchiveFolder(selected) {
    if (selected.name === 'Diario dei sogni') return selected;
    try {
      await selected.getFileHandle('diario-sogni-archive.json');
      return selected;
    } catch (error) {
      if (error.name !== 'NotFoundError') throw error;
    }
    return selected.getDirectoryHandle('Diario dei sogni', {create: true});
  }
  scope.dreamArchiveResolveFolder = resolveArchiveFolder;
  if (typeof module !== 'undefined' && module.exports) module.exports = resolveArchiveFolder;
})(typeof window === 'undefined' ? globalThis : window);
