"""Check an APK before upload. Print only counts and member names, never paths."""
import argparse
import json
import re
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('apk')
args = parser.parse_args()
patterns = [
    re.compile(rb'(?i)[a-z]:[/\\]+users[/\\]+'),
    re.compile(rb'/(?:Users|home)/[^/\x00\s]+/'),
]
findings = []
with zipfile.ZipFile(args.apk) as archive:
    members = archive.namelist()
    for member in members:
        if member.endswith('/'):
            continue
        data = archive.read(member)
        count = sum(len(pattern.findall(data)) for pattern in patterns)
        if count:
            findings.append({'member': member, 'personal_path_count': count})
    forbidden = [name for name in members if re.search(r'(?i)(ffmpeg|libavcodec|libavformat|libavutil|libswresample|libswscale)', name)]
print(json.dumps({'personal_paths': findings, 'obsolete_audio_libraries': forbidden}, ensure_ascii=False))
raise SystemExit(1 if findings or forbidden else 0)
