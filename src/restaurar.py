import json
import shutil
from pathlib import Path
from packtools import sha256

ROOT=Path(__file__).resolve().parent
if __name__=='__main__':
    manifest=json.loads((ROOT/'installation.json').read_text(encoding='utf8'))
    backup=ROOT/'PokemonBattleAdvanced.before-coop.pck'
    target=ROOT/'PokemonBattleAdvanced.pck'
    if sha256(backup)!=manifest['source_pack_sha256']:
        raise SystemExit('Backup não confere; restauração interrompida.')
    if sha256(target) not in [manifest['coop_pack_sha256'],manifest['source_pack_sha256']]:
        raise SystemExit('PCK atual desconhecido; restauração interrompida para preservar alterações.')
    shutil.copy2(backup,target)
    if sha256(target)!=manifest['source_pack_sha256']:
        raise SystemExit('Falha na verificação após restaurar.')
    print('PCK anterior restaurado, incluindo Thunder Stone e Haunter por troca.')
    print('Os arquivos e saves da pasta original nunca foram substituídos.')
