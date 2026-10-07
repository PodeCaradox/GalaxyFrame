// Linux launcher (Steam Frame): the game code assumes a 32-bit address space,
// so the executable is linked at 0x98000000, the slot libgame.so takes on
// Android, and the rest of the window 0x80000000-0xE0010000 is reserved around
// it before the game maps MEM1/MEM2 there.
//
//   galaxyquest                                        the VR app
//   galaxyquest --headless <data root> <save root> [s] the bring-up runner
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>

#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE 0x100000
#endif

static const uintptr_t kWindowBase = 0x80000000u;
static const size_t kWindowSize = 0x60010000u;  // up to 0xE0010000 (locked cache)
static const uintptr_t kImageBase = 0x98000000u;
static const size_t kImageSlot = 0x08000000u;  // the executable and the start of its heap

extern char _end[];  // end of the executable's image (lld)

void port_linux_main(uintptr_t windowBase, size_t windowSize);
int port_headless_main(int argc, char** argv);

static void reserve(uintptr_t lo, uintptr_t hi) {
    void* p = mmap((void*)lo, hi - lo, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
    if (p == (void*)lo) {
        return;
    }
    fprintf(stderr, "cannot reserve the game address window %p-%p (got %p, errno %d)\n", (void*)lo, (void*)hi, p, errno);
    FILE* f = fopen("/proc/self/maps", "r");
    char line[512];
    while (f && fgets(line, sizeof(line), f)) {
        fputs(line, stderr);
    }
    exit(1);
}

// The kernel starts the brk heap up to 1 GB past a non-PIE executable, which
// can be inside the window.  Reserved from .preinit_array, before any
// library's constructor makes the heap, the window wins and malloc uses mmap.
static void reserveWindow(int argc, char** argv, char** envp) {
    (void)argc;
    (void)argv;
    (void)envp;
    if ((uintptr_t)_end > kImageBase + kImageSlot) {
        fprintf(stderr, "the executable ends at %p, past its slot (%p)\n", (void*)_end, (void*)(kImageBase + kImageSlot));
        exit(1);
    }
    reserve(kWindowBase, kImageBase);
    reserve(kImageBase + kImageSlot, kWindowBase + kWindowSize);
}
__attribute__((section(".preinit_array"), used)) static void (*sReserveWindow)(int, char**, char**) = reserveWindow;

int main(int argc, char** argv) {
    // The disc layer keeps each game file open once read (2,400 files); a
    // shell's soft limit is 1024.
    struct rlimit files;
    if (getrlimit(RLIMIT_NOFILE, &files) == 0 && files.rlim_cur < files.rlim_max) {
        files.rlim_cur = files.rlim_max;
        setrlimit(RLIMIT_NOFILE, &files);
    }
    // SteamOS lets a game raise its priority (RLIMIT_NICE's hard limit is 28
    // there: down to nice -8), so the frame loop keeps its refreshes while
    // other apps want the same cores (a chat client took two of them).  Every
    // thread started from here on inherits it.
    struct rlimit nice;
    if (getrlimit(RLIMIT_NICE, &nice) == 0 && nice.rlim_max > 20) {
        nice.rlim_cur = nice.rlim_max;
        if (setrlimit(RLIMIT_NICE, &nice) == 0) {
            setpriority(PRIO_PROCESS, 0, 20 - (int)(nice.rlim_max > 40 ? 40 : nice.rlim_max));
        }
    }
    if (argc > 1 && strcmp(argv[1], "--headless") == 0) {
        return port_headless_main(argc - 1, argv + 1);
    }
    port_linux_main(kWindowBase, kWindowSize);
    return 0;
}
