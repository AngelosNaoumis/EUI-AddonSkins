"""Compare identical synthetic workloads in isolated Lua states (five trials)."""
import argparse
import ctypes
import json
import statistics
from pathlib import Path

lua = ctypes.CDLL('liblua5.4.so.0')
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
# Capture print inside Lua so timing output is parsed without spawning processes.
parser = argparse.ArgumentParser()
parser.add_argument("--baseline", default="audit/baseline/EUIAddonSkins", help="Directory containing the original addon files")
args = parser.parse_args()
results = {}
for label, directory in [('before', args.baseline), ('after', 'EUIAddonSkins')]:
    trials = []
    for _ in range(5):
        state = lua.luaL_newstate(); lua.luaL_openlibs(state)
        try:
            code = ('BENCH_ROOT = ' + json.dumps(directory) + '\n'
                    'print = function(s) BENCH_RESULT = s end\n' + Path('benchmarks/scan.lua').read_text()
                    + '\nreturn BENCH_RESULT')
            rc = lua.luaL_loadstring(state, code.encode())
            if not rc: rc = lua.lua_pcallk(state, 0, 1, 0, 0, None)
            value = lua.lua_tolstring(state, -1, None).decode()
            if rc: raise RuntimeError(value)
            trials.append([float(x) for x in value.split()[1:]])
        finally:
            lua.lua_close(state)
    keys = ['cpu_seconds', 'allocated_kib_gc_stopped', 'frames_visited', 'children_enumerations', 'alpha_writes', 'full_scans', 'initial_hooks']
    results[label] = dict(zip(keys, [statistics.median(values) for values in zip(*trials)]))
print(json.dumps({'environment': 'Lua 5.4 synthetic UI, 200 scroll events; median of five trials; GC stopped during measured loop', 'results': results}, indent=2))
