// Native (Universal) entry point for Steam.app.
// It is native so the app itself is never an Intel app; it hands off to launch.sh,
// which checks Rosetta (Wine is still Intel-only) and then runs steam.sh.
#include <libgen.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    char raw[PATH_MAX], exe[PATH_MAX], script[PATH_MAX];
    uint32_t size = sizeof(raw);
    if (_NSGetExecutablePath(raw, &size) != 0 || !realpath(raw, exe)) {
        fprintf(stderr, "Steam.app: cannot resolve its own path\n");
        return 1;
    }
    // exe = .../Steam.app/Contents/MacOS/Steam  ->  .../Steam.app/Contents
    char *contents = dirname(dirname(exe));
    snprintf(script, sizeof(script), "%s/Resources/launch.sh", contents);

    // Finder passes -psn_* on old systems; drop it, keep anything else.
    char **args = calloc(argc + 2, sizeof(char *));
    int n = 0;
    args[n++] = "/bin/bash";
    args[n++] = script;
    for (int i = 1; i < argc; i++)
        if (strncmp(argv[i], "-psn_", 5) != 0) args[n++] = argv[i];
    args[n] = NULL;

    execv("/bin/bash", args);
    perror("Steam.app: execv /bin/bash");
    return 1;
}
