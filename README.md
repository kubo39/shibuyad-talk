# shibya.d 2

## benchmark

### std.datetime.benchmark

```d
    auto results = benchmark!(makeSlice, makeSliceOpt)(100);
    foreach (r; results)
        r.to!Duration.writeln;
/*
$ shibuyad-talk% rdmd benchmark1.d
74 ms, 173 μs, and 9 hnsec
41 ms, 427 μs, and 2 hnsec
*/
```

## CPU profiling

### dmd -profile

- dmd -profile
    - QueryPerformanceCounter (Windows)
    - rdtsc (Other OSs, x86/x86_64)

```console
$ dmd -g -profile dmdprofile.d
$ cat trace.log
```

### valgrind

```console
% valgrind --tool=callgrind ./dmdprofile
==25424== Callgrind, a call-graph generating cache profiler
==25424== Copyright (C) 2002-2013, and GNU GPL'd, by Josef Weidendorfer et al.
==25424== Using Valgrind-3.10.0 and LibVEX; rerun with -h for copyright info
==25424== Command: ./dmdprofile
==25424==
==25424== For interactive control, run 'callgrind_control -h'.
==25424==
==25424== Events    : Ir
==25424== Collected : 682915
==25424==
==25424== I   refs:      682,915
% callfring_annoate callgrind.out.25424
... # なんかいっぱいでる
```

### perf (Linux)

```console
# perf record dmdprofile
# perf report
... # なんかでる
```

## Memory Profiling

### generic primitive

- mallinfo(3) (Linux/Glibc)
- proc/[PID]/statm (Linux)

```d
extern(C) {
    struct mallinfo_ {
        ...
    }
    mallinfo_ mallinfo();
}
```

### DUB Package

- [resusage](http://code.dlang.org/packages/resusage)

* process: `/proc/[PID]/stat`
* system: `sysinfo(3)`
