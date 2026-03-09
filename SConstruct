#!/usr/bin/env python
import os
import sys
from glob import glob
from pathlib import Path

from methods import print_error


if not (os.path.isdir("godot-cpp") and os.listdir("godot-cpp")):
    print_error("""godot-cpp is not available within this folder, as Git submodules haven't been initialized.
Run the following command to download godot-cpp:

    git submodule update --init --recursive""")
    sys.exit(1)

customs = ["custom.py"]
customs = [os.path.abspath(path) for path in customs]

localEnv = Environment(tools=["default"], PLATFORM="")
opts = Variables(customs, ARGUMENTS)
opts.Update(localEnv)
Help(opts.GenerateHelpText(localEnv))

env = localEnv.Clone()
env = SConscript("godot-cpp/SConstruct", {"env": env, "customs": customs})

env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

# Auto-discover the .gdextension path and output binaries to the addon's bin/ folder
(extension_path,) = glob("project/addons/*/*.gdextension")
addon_path = Path(extension_path).parent
project_name = Path(extension_path).stem

scons_cache_path = os.environ.get("SCONS_CACHE")
if scons_cache_path is not None:
    CacheDir(scons_cache_path)

debug_or_release = "release" if env["target"] == "template_release" else "debug"
if env["platform"] == "macos":
    library = env.SharedLibrary(
        "{0}/bin/lib{1}.{2}.{3}.framework/{1}.{2}.{3}".format(
            addon_path, project_name, env["platform"], debug_or_release,
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "{}/bin/lib{}.{}.{}.{}{}".format(
            addon_path, project_name, env["platform"], debug_or_release,
            env["arch"], env["SHLIBSUFFIX"],
        ),
        source=sources,
    )

Default(library)
