"""Runs actual campaign processes. No fake damage, network or world scene."""
from pathlib import Path
import subprocess,os,time,json,argparse
HERE=Path(__file__).resolve().parent

def run(runtime,logs,case,port,visible=False,trainer='youngster_ryan',import_save=False,start='route2'):
    logs=logs/case;logs.mkdir(parents=True,exist_ok=True)
    ps=[];records={}
    try:
        for role in ['host','guest']:
            data=(logs/('userdata_'+role)).resolve();data.mkdir(exist_ok=True)
            if import_save:
                import shutil
                fixture=HERE/'fixtures'/(role+'.json')
                d=json.loads(fixture.read_text(encoding='utf8'));d['game_version']='0.6.2a'
                # Actual SaveGame format from campaign, with this side's own party.
                dest=data/'Godot/app_userdata/Pokémon Battle Advanced';dest.mkdir(parents=True,exist_ok=True)
                (dest/'campaign_input.json').write_text(json.dumps(d),encoding='utf8')
            env=os.environ.copy();env['APPDATA']=str(data)
            cmd=[str(runtime/'PokemonBattleAdvanced.exe')]
            if not visible:cmd+=['--headless']
            cmd+=['--','--coop-campaign','--coop-role='+role,'--coop-port='+str(port),'--coop-autotest','--coop-test='+case,'--coop-trainer='+trainer,'--coop-start='+start]
            f=(logs/(role+'.txt')).open('w',encoding='utf8')
            p=subprocess.Popen(cmd,cwd=runtime,env=env,stdout=f,stderr=f)
            ps.append((role,p,f,data));time.sleep(1)
        until=time.monotonic()+160
        while any(p.poll() is None for _,p,_,_ in ps) and time.monotonic()<until:time.sleep(.25)
        for role,p,f,data in ps:
            assert p.poll() is not None,(case,role,'timeout')
            f.close()
            assert p.returncode==0,(case,role,p.returncode)
            text=(logs/(role+'.txt')).read_text(encoding='utf8')
            assert 'SCRIPT ERROR' not in text,(case,role,'SCRIPT ERROR')
            assert 'unknown peer' not in text,(case,role,'unknown peer')
            audit=next(data.rglob('campaign_audit.jsonl'))
            records[role]=[json.loads(s) for s in audit.read_text(encoding='utf8').splitlines()]
            (logs/(role+'.jsonl')).write_bytes(audit.read_bytes())
        for role,rows in records.items():
            expected_scene='res://scenes/interiors/pewter_city_interiors.tscn' if start=='brock' or (start=='split' and role=='host') else 'res://scenes/world/overworld.tscn'
            assert any(r['event']=='campaign_ready' and r['scene']==expected_scene for r in rows)
            assert any(r['event']=='connected' for r in rows)
            assert any(r['event']=='save_guard' and not r['write_allowed'] for r in rows)
            if start!='split' or role=='host': assert len([r for r in rows if r['event']=='presence'])>=1
            if not case.startswith('prepare_drop_'):
                assert any(r['event']=='battle_started' and r['id']==trainer for r in rows),(case,role,'battle not started')
            if case in ['drop_'+role,'prepare_drop_'+role]:
                assert any(r['event']=='injected_exit' for r in rows)
                continue
            returns=[r for r in rows if r['event']=='returned_to_campaign']
            assert returns,(case,role,'no return')
            for r in returns:
                assert not r['battle'] and r['controls'] and not r['trainer_defeated'],r
                assert r['money']==r['saved_money'],r
                assert r['flags_restored'] and r['party_restored'],r
                if start=='split': assert r['scene']==expected_scene,(role,r)
            if start=='split' and role=='guest':
                assert any(r['event']=='join_map_done' for r in rows),(case,role,'no join')
                assert any(r['event']=='return_map_done' and r.get('zone')=='route_2' for r in rows),(case,role,'no return zone')
            if case=='travel' and role=='host':
                assert any(r['event']=='travel_done' and r['connected'] and r['scene']=='res://scenes/world/overworld.tscn' and r['zone']=='route_2' for r in rows),(case,role,'travel failed')
                assert any(r['event']=='map_rebound' and r['scene']=='res://scenes/world/overworld.tscn' for r in rows),(case,role,'no rebind')
            controls=[r for r in rows if r['event']=='return_control']
            assert controls and all(r['enabled'] and r['moved'] and not r['battle'] for r in controls),controls
            expected='lost' if case=='lose' else ('aborted' if case=='abort' else ('disconnected' if 'drop_' in case else 'won'))
            assert returns[-1]['result']==expected,(case,role,returns[-1])
            if case=='repeat':assert len(returns)==2,(role,len(returns))
        sent={(r.get('number',1),r['seq']):r['hp'] for r in records['host'] if r['event']=='snapshot_sent'}
        applied=[r for r in records['guest'] if r['event']=='snapshot_applied']
        # Sequences restart per encounter; include encounter number in audit.
        assert all(sent[(r.get('number',1),r['seq'])]==r['hp'] for r in applied)
        if not case.startswith('prepare_drop_'):assert len(applied)>10
        results=[r for r in records['host'] if r['event']=='host_result']
        if case in ['win','pad','repeat','visual','drew','save','odd','waves','slot1','out_lead','picnic','travel']:
            assert results and all(all(x>0 for x in r['damage']) for r in results),results
            assert all(all(r['moved']) for r in results),results
        if case not in ['abort','lose','drop_host','drop_guest','prepare_drop_host','prepare_drop_guest']:
            for role in ['host','guest']:
                starts=[r for r in records[role] if r['event']=='battle_started']
                assert starts and all(len(r['species'])==4 for r in starts),(case,role,starts)
                assert all(len(r['hp'])==4 and r['hp'][2:]==[0,0] for r in records[role] if r['event'] in ['host_result','guest_result']),(case,role)
        if case=='odd':
            assert any(r['event']=='roster_balanced' and r['added']=='Pidgey' for r in records['host'])
        if case=='waves':
            for role in ['host','guest']:
                assert len([r for r in records[role] if r['event']=='foe_replaced'])>=2,(case,role)
        if case=='slot1':
            for role in ['host','guest']:
                assert any(r['event']=='foe_replaced' and r['slot']==1 for r in records[role]),(case,role)
        assert any(r['event']=='guest_entry_reveal' for r in records['guest']) if case not in ['prepare_drop_host','prepare_drop_guest'] else True
        if case=='pad':
            assert any(r['event']=='synthetic_pad_read' for r in records['guest'])
            assert any(r['event']=='synthetic_pad_read' and r['move']!='(0.0, 0.0)' for r in records['guest'])
            assert any(r['event']=='remote_edge' and r['slot']==0 for r in records['host'])
        summary={'case':case,'trainer':trainer,'passed':True,'snapshots':len(applied),'host_results':results,'physical_gamepad_tested':False}
        (logs/'result.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
        print(json.dumps(summary),flush=True)
        return summary
    finally:
        for _,p,f,_ in ps:
            if p.poll() is None:p.kill();p.wait()
            f.close()

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    default_runtime=next((d for d in [HERE.parent/'PBA-Coop-Duplas-V8',HERE/'PBA-Coop-Duplas-V8'] if (d/'installation.json').is_file()),HERE.parent/'PBA-Coop-Duplas-V8')
    ap.add_argument('--runtime',type=Path,default=default_runtime)
    ap.add_argument('--logs',type=Path,default=HERE/'logs/validation')
    ap.add_argument('--case',default='win')
    ap.add_argument('--port',type=int,default=24820)
    ap.add_argument('--visible',action='store_true')
    ap.add_argument('--trainer',default='youngster_ryan')
    ap.add_argument('--start',default='route2')
    ap.add_argument('--import-save',action='store_true')
    args=ap.parse_args()
    run(args.runtime.resolve(),args.logs.resolve(),args.case,args.port,args.visible,args.trainer,args.import_save,args.start)
