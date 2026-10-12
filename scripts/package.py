"""Build and verify a versioned addon ZIP from the files in its TOC."""
from pathlib import Path
import re
import shutil
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
addon = root / 'EUIAddonSkins'
license_bytes = (root / 'LICENSE').read_bytes()
(addon / 'LICENSE').write_bytes(license_bytes)
toc = (addon / 'EUIAddonSkins.toc').read_text()
version = re.search(r'^## Version: (\S+)$', toc, re.M).group(1)
assert f'ns.VERSION = "{version}"' in (addon / 'Core.lua').read_text(), 'Version mismatch'
loaded = [line.strip().replace('\\', '/') for line in toc.splitlines() if line.strip() and not line.startswith('#')]
for path in loaded:
    assert (addon / path).is_file(), f'Missing TOC file: {path}'
assert {f.relative_to(addon).as_posix() for f in (addon / 'Skins').glob('*.lua')} == {p for p in loaded if p.startswith('Skins/')}, 'Unloaded skin files would be bundled'
for name in ['ForeverCompanion', 'ForeverDungeonJournal', 'RXPGuides', 'Auctionator', 'Spy', 'WhatsTraining', 'ItemRack', 'KiwiFarm', 'Myslot', 'BugSack', 'Altoholic', 'Attune', 'TwitchEmotes', 'Questie', 'DBM', 'AtlasLootContinued', 'GTFO', 'Gargul']:
    assert f'Skins/{name}.lua' in loaded, f'Skin not loaded: {name}'
subprocess.run([sys.executable, 'tests/run_lua.py'], cwd=root, check=True)
archive = root / f'EUIAddonSkins-{version}.zip'
# Match .pkgmeta's player payload; retain these documents in the repository.
excluded = {'README.md', 'CHANGELOG.md'}
files = sorted(f for f in addon.rglob('*') if f.is_file()
               and f.relative_to(addon).as_posix() not in excluded
               and not any(part.startswith('.') for part in f.relative_to(addon).parts))
with ZipFile(archive, 'w', compression=ZIP_DEFLATED) as z:
    for f in files:
        z.write(f, f.relative_to(root).as_posix())
with ZipFile(archive) as z:
    assert z.testzip() is None, 'Corrupt ZIP'
    assert z.read('EUIAddonSkins/LICENSE') == license_bytes, 'Release license differs from root LICENSE'
    assert set(z.namelist()) == {f.relative_to(root).as_posix() for f in files}
    for f in files:
        assert z.read(f.relative_to(root).as_posix()) == f.read_bytes()
shutil.copyfile(archive, root / 'EUIAddonSkins.zip')
print(f'Verified {archive.name}: {len(files)} files, all eighteen skins loaded by the TOC')
