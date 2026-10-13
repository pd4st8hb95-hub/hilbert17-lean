#!/usr/bin/env python3
"""Root-owned, source-frozen offline Lake verification; never run during staging."""
import argparse, fcntl, hashlib, importlib.util, json, os, re, signal, subprocess, sys, time, tomllib
from pathlib import Path

WORK = Path(__file__).resolve().parent
PORTABLE = WORK.parent / 'hilbert17-portable-check'
CORE_HASH = '390d24bf21a2e13874c631965503c69d7d2bc62c0f2298c63fb776e93bd4a9ee'
MODULE = re.compile(r'[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\Z')
ACTIVE = None

def read_json(path):
    return json.loads(Path(path).read_text())

def require(condition, message):
    if not condition:
        raise RuntimeError(message)

def group_compilers(pgid, lean, allowed_sources):
    """Runtime backstop; the dependency precheck is the primary serial gate."""
    found, observed = [], []
    for proc in Path('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            if os.getpgid(int(proc.name)) != pgid:
                continue
            exe = (proc / 'exe').resolve(strict=True)
            args = [x.decode() for x in (proc / 'cmdline').read_bytes().split(b'\0') if x]
            if exe == lean:
                sources = [x for x in args[1:] if x.endswith('.lean')]
                if sources:
                    cwd = (proc / 'cwd').resolve(strict=True)
                    resolved = {(cwd / x).resolve() for x in sources}
                    observed.extend(str(x) for x in resolved)
                    if len(resolved) != 1 or not resolved <= allowed_sources:
                        return 'UNEXPECTED_LEAN_SOURCE', found + [int(proc.name)], observed
                    found.append(int(proc.name))
            elif exe.name.startswith('clang') or exe.name in {'cc', 'gcc', 'leanc', 'npm', 'curl', 'wget'}:
                return 'UNEXPECTED_EXTERNAL_BUILD_OR_NETWORK_PROCESS', found, observed
            elif exe.name == 'git' and any(x in {'fetch', 'clone', 'pull', 'push'} for x in args[1:]):
                return 'UNEXPECTED_GIT_NETWORK_OPERATION', found, observed
        except (FileNotFoundError, ProcessLookupError):
            continue
    return ('MULTIPLE_LEAN_COMPILERS' if len(found) > 1 else None), found, observed

def run_command(g, label, command, allowed, configs, lean, env, run, ordinal):
    global ACTIVE
    prefix = run / f'{ordinal:03d}-{label.replace(".", "_").replace(":", "_")}'
    before = g.memory()
    row = dict(label=label, command=command, start_utc=g.now(), memory_before=before,
               stdout=str(prefix)+'.stdout.log', stderr=str(prefix)+'.stderr.log',
               allowed_configuration_sources=sorted(str(p) for p in configs))
    status = Path(str(prefix)+'.json')
    if before['used_percent'] >= g.REFUSE:
        row['status'] = 'REFUSED_MEMORY_AT_OR_ABOVE_60_PERCENT'
        g.write_json(status, row)
        return row
    g.write_json(status, dict(row, status='STARTING'))
    print('START', label, flush=True)
    started, term_at, reason, warned = time.monotonic(), None, None, False
    peak = before['used_percent']; observed_sources=set()
    with open(row['stdout'], 'wb') as out, open(row['stderr'], 'wb') as err, \
            open(str(prefix)+'.memory.jsonl', 'w') as samples:
        try:
            ACTIVE = subprocess.Popen(command, cwd=PORTABLE, env=env, stdin=subprocess.DEVNULL,
                                      stdout=out, stderr=err, start_new_session=True)
            row.update(pid=ACTIVE.pid, status='RUNNING')
            g.write_json(status, row)
            while ACTIVE.poll() is None:
                sample = g.memory(); used = sample['used_percent']; peak = max(peak, used)
                violation, compilers, observed = group_compilers(ACTIVE.pid, lean, allowed | configs)
                sample['lean_compilers'] = compilers
                sample['lean_source_paths'] = observed; observed_sources.update(observed)
                samples.write(json.dumps(sample)+'\n'); samples.flush()
                if violation:
                    reason = violation
                    g.group_signal(ACTIVE, signal.SIGKILL)
                elif used >= g.KILL:
                    reason = 'KILLED_MEMORY_AT_OR_ABOVE_75_PERCENT'
                    g.group_signal(ACTIVE, signal.SIGKILL)
                elif term_at is None and used >= g.TERM:
                    reason, term_at = 'TERMINATED_MEMORY_AT_OR_ABOVE_70_PERCENT', time.monotonic()
                    g.group_signal(ACTIVE, signal.SIGTERM)
                elif term_at is not None and time.monotonic()-term_at >= g.GRACE:
                    reason = 'KILLED_AFTER_5_SECOND_TERM_GRACE'
                    g.group_signal(ACTIVE, signal.SIGKILL)
                if used >= g.WARN and not warned:
                    print(f'MEMORY WARNING {used:.2f}% during {label}', flush=True); warned = True
                time.sleep(0.5)
            code = ACTIVE.wait()
            # A terminating Lake process must not leave an unmonitored child group.
            g.group_signal(ACTIVE, signal.SIGKILL)
        except BaseException:
            if ACTIVE is not None:
                g.group_signal(ACTIVE, signal.SIGKILL); ACTIVE.wait()
            row.update(status='ABORTED', end_utc=g.now()); g.write_json(status, row)
            raise
        finally:
            ACTIVE = None
    row.update(status=reason or ('PASS' if code == 0 else 'COMMAND_FAILED'), exit_code=code,
               end_utc=g.now(), seconds=round(time.monotonic()-started, 3),
               peak_physical_used_percent=peak, memory_after=g.memory(),
               observed_configuration_compiles=sorted(observed_sources & {str(p) for p in configs}),
               configuration_observation_scope='0.5-second process samples; configuration input pins are also recorded. Short-lived or in-process elaboration is not exhaustively observed.')
    g.write_json(status, row); print(row['status'], label, flush=True)
    return row

def main():
    def interrupted(signum, _frame):
        raise KeyboardInterrupt(f'Received signal {signum}')
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    ap=argparse.ArgumentParser(); ap.add_argument('--plan', required=True)
    ap.add_argument('--plan-sha256', required=True); ap.add_argument('--run-name', required=True)
    args=ap.parse_args()
    core=WORK/'guarded_compile03.py'
    require(hashlib.sha256(core.read_bytes()).hexdigest()==CORE_HASH, 'Guard core mismatch')
    spec=importlib.util.spec_from_file_location('lake_guard',core); g=importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
    p=Path(args.plan).resolve(); require(p.is_relative_to(PORTABLE), 'Plan outside portable workspace')
    require(g.digest(p)==args.plan_sha256, 'Plan hash mismatch'); plan=read_json(p)
    require(plan['schema']=='hilbert17-portable-lake-command-plan-v1', 'Wrong plan schema')
    require(plan.get('status')=='READY_FOR_ROOT_REVIEW', 'Plan is not fully frozen')
    require(Path(plan['workspace']).resolve()==PORTABLE, 'Wrong portable workspace')
    require(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,90}',args.run_name), 'Invalid run name')
    for key in ['lake','lean','allowlist','manifest','overrides','root_config','guard_core','initial_inputs','runner']:
        g.check_pin(plan[key])
    require(Path(plan['runner']['path']).resolve()==Path(__file__).resolve(),'Runner path mismatch')
    for pin in plan['private_package_configs']:g.check_pin(pin)
    config_sources={Path(pin['path']).resolve() for pin in plan['private_package_configs'] if Path(pin['path']).name=='lakefile.lean'}
    require(config_sources=={PORTABLE/'.lake/packages/mathlib/lakefile.lean',PORTABLE/'.lake/packages/proofwidgets/lakefile.lean'},'Unexpected Lean configuration source scope')
    require(plan['guard_core']['sha256']==CORE_HASH,'Wrong guard pin')
    config=read_json(WORK/'local-runtime.json')
    require(plan['lean']==config['compiler'], 'Lean compiler pin changed')
    lake=Path(plan['lake']['path']).resolve(); lean=Path(plan['lean']['path']).resolve()
    require(lake==lean.parent/'lake','Lake and Lean must share pinned installation')
    initial=read_json(plan['initial_inputs']['path'])
    for pin in initial['pins']:
        require(Path(pin['path']).resolve().is_relative_to(PORTABLE),'Initial input escapes portable workspace')
        g.check_pin(pin)
    allow=read_json(plan['allowlist']['path']); entries=allow['official_modules']+allow['local_modules']+allow['aggregate_modules']
    require(all(x.get('source') for x in entries),'Pending source in allowlist')
    pins={x['module']:x['source'] for x in entries}
    require(len(pins)==len(entries),'Duplicate allowed module')
    require(len(plan['jobs'])==len(pins),'Allowlist/job count mismatch')
    base=[str(lake),'--dir',str(PORTABLE),'--no-cache','--packages='+plan['overrides']['path']]
    for job in plan['jobs']:
        m=job['module']; require(MODULE.fullmatch(m),'Invalid module')
        require(job['source']==pins[m],'Job source pin mismatch'); g.check_pin(pins[m])
        require(Path(pins[m]['path']).resolve().is_relative_to(PORTABLE),'Source outside portable workspace')
        require(job['prerequisite_check']==base+['--no-build','build','+'+m+':deps'],'Unexpected dependency command')
        require(job['build']==base+['build','+'+m+':olean'],'Unexpected build command')
    targets=['Hilbert17','Hilbert17RealClosure','Hilbert17Full','Hilbert17Acceptance']
    require(plan['aggregate_targets']==targets,'Unexpected library target scope')
    root_config=tomllib.loads(Path(plan['root_config']['path']).read_text())
    require(root_config['defaultTargets']==targets,'Delivery/default target mismatch')
    require({x['name'] for x in root_config['lean_lib']}==set(targets),'Library target mismatch')
    require(plan['aggregate_build']==base+['build']+targets,'Unexpected aggregate command')
    require(plan['final_up_to_date_check']==base+['--no-build','build']+targets,'Unexpected final check')
    override_document=read_json(plan['overrides']['path']); manifest=read_json(plan['manifest']['path'])
    require(override_document.get('schemaVersion')=='1.2.0','Unexpected package override schema')
    overrides=override_document['packages']
    require({x['name'] for x in overrides}=={x['name'] for x in manifest['packages']},'Missing dependency override')
    require(all(x['type']=='path' and (PORTABLE/x['dir']).resolve()==PORTABLE/'.lake/packages'/x['name'] for x in overrides),'Nonlocal dependency override')
    # Copied cache/source symlinks may only resolve inside the isolated package.
    for root, dirs, files in os.walk(PORTABLE):
        for name in dirs+files:
            q=Path(root)/name
            if q.is_symlink():require(q.resolve().is_relative_to(PORTABLE),'Escaping portable symlink')
    run=g.validate_write_path(WORK/'verification'/args.run_name,WORK/'verification')
    run.mkdir(exist_ok=False)
    lock=(WORK/'verification/runtime-compile.lock').open('a'); fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    for sub in ['home','tmp']:(run/sub).mkdir()
    env=plan['environment'].copy(); env.update(HOME=str(run/'home'),TMPDIR=str(run/'tmp'))
    require(env.get('LEAN_PATH')=='' and env.get('LEAN_SRC_PATH')=='','External module search path')
    require(env.get('LAKE_NO_CACHE')=='1' and env.get('LAKE_ARTIFACT_CACHE')=='false','Cache downloads not disabled')
    summary=dict(status='RUNNING',started_utc=g.now(),plan=str(p),plan_sha256=args.plan_sha256,
                 driver_sha256=g.digest(__file__),environment=env,jobs=[],scope=plan['serial_strategy'])
    out=run/'summary.json'; g.write_json(out,summary); ordinal=0
    fixed=list(pins.values())+plan['private_package_configs']+[plan['root_config'],plan['manifest'],plan['overrides']]
    def execute(label,cmd,allowed):
        nonlocal ordinal
        for pin in fixed:g.check_pin(pin)
        ordinal+=1; row=run_command(g,label,cmd,allowed,config_sources,lean,env,run,ordinal)
        summary['jobs'].append(row);g.write_json(out,summary)
        for pin in fixed:g.check_pin(pin)
        return row['status']=='PASS'
    def output_pins(module):
        root=PORTABLE/'.lake/packages/mathlib' if module.startswith('Mathlib.') else PORTABLE
        rel=Path(*module.split('.')); records=[]
        for folder,suffixes in [('.lake/build/lib/lean',['.olean','.olean.private','.olean.server','.ilean','.ir','.trace']),('.lake/build/ir',['.c','.setup.json'])]:
            for suffix in suffixes:
                path=g.validate_write_path(root/folder/rel.with_suffix(suffix),PORTABLE)
                if path.is_file():records.append(dict(path=str(path),bytes=path.stat().st_size,sha256=g.digest(path)))
        return records
    try:
        # Both phases use exactly the same frozen package configuration and environment.
        for job in plan['jobs']:
            m=job['module']; source=Path(job['source']['path']).resolve()
            if not execute(m+':deps',job['prerequisite_check'],set()):
                summary['status']='STOPPED_ON_UNEXPECTED_STALE_DEPENDENCY_OR_FAILURE';return 1
            if not execute(m+':olean',job['build'],{source}):
                summary['status']='STOPPED_ON_FIRST_BUILD_FAILURE_OR_RESOURCE_LIMIT';return 1
            summary['jobs'][-1]['outputs']=output_pins(m);g.write_json(out,summary)
        # At this point the aggregate build must only reuse existing artifacts.
        for label,key in [('aggregate','aggregate_build'),('up-to-date','final_up_to_date_check')]:
            if not execute(label,plan[key],set()):
                summary['status']='STOPPED_ON_AGGREGATE_FAILURE';return 1
        summary['status']='ALL_BOUNDED_OFFLINE_LAKE_BUILDS_PASS';return 0
    except BaseException as exc:
        summary.update(status='ABORTED',error=f'{type(exc).__name__}: {exc}');raise
    finally:
        summary['ended_utc']=g.now();g.write_json(out,summary);print('SUMMARY',summary['status'],out,flush=True)

if __name__=='__main__':
    sys.exit(main())
