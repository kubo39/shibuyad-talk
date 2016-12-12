# shibya.d 2

---

## benchmark

- benchmarkはエビデンス
    - 提案がほんとに効果あるかとか
    - パフォーマンスに影響があるorないの証明とか
- ツールうんぬんよりもいろいろなパターンでとるのが大事

---

### std.datetime.benchmark

- std.datetimeにはbenchmark関数以外もあるけど、まあお好みで
    - 表示が弱い(だめじゃんね…)
- なんでstd.datetime...?

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

---

## CPU profiling

- 推測するな、計測せよ
    - どうやってボトルネックみつけるか
    - 勘とか、知識とかまあ悪くはないけど
        - 実は最適化してくれてるとかコードみただけでわかります？
        - けっきょくボトルネックじゃないかもしれない

---

### dmd -profile

- dmd -profile
    - QueryPerformanceCounter (Windows)
    - rdtsc (Other OSs, x86/x86_64)

```console
$ dmd -g -profile dmdprofile.d
$ cat trace.log
```

- ここがいい: D言語のruntime側でhookしてるので余計な情報が入らない、使うの簡単
- ここがだめ: D関係ないとこはとれない(runtimeをskipするとだめ)、とれるプラットフォームは限定的

---

### perf (1)

- Performance Counter (`CPU_CLK_UNHALTED`) + ftraceなsampling profiler
    - ftraceでカーネルの関数とかにもフック
    - msrレジスタが〜とか書こうと思ったけどめんどくさくなった
- rdtscと比べると低消費電力モードの影響を受けない
- 総instruction数、L1/L2キャッシュヒット率とかもわかる

```console
# perf record dmdprofile
# perf report
... # なんかでる
```

- ここがいい: 使うの簡単、かなりいろいろとれる
- ここがだめ: 使えるのはLinuxのみ、root権限が必要
    - まあ*BSDならDTraceでしょ、という

---

### valgrind

- callgrindとかcachegrindとか
- 何回呼び出されるか、全体の割合でどのくらいかとか
- LinuxではDWARFの情報読む
- OSXでも動いてくれる

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

- ここがいい: プラットフォームの差異は吸収、使うのも難しくはない
- ここがだめ: めちゃくちゃ遅い、実行時profilingなんてもってのほか

---

### 他にもいろいろある

- oproifle
    - 昔は割り込み式だったけど今はperfと同じかんじに動く
- Google CPU Profiler
    - C/C++向けのSampling Profiler
    - pprof(Go)とかstackprof(Ruby)とかに影響
    - 本番環境でもprofilingできるのが嬉しい

まあ長くなりすぎるので…

---

## Memory Profiling

---

### GC Configuration

- 最近は実行時にGC向けのConfigを喰わせられるように

http://dlang.org/spec/garbage.html

```
 $ ./gctuning "--DRT-gcopt=profile:2 minPoolSize:16"
        Number of collections:  5
        Total GC prep time:  0 milliseconds
        Total mark time:  1 milliseconds
        Total sweep time:  0 milliseconds
        Total page recovery time:  0 milliseconds
        Max Pause Time:  0 milliseconds
        Grand total GC time:  1 milliseconds
GC summary:  268 MB,    5 GC    1 ms, Pauses    1 ms <    0 ms
```

---

### OS/libc

- 生でさわることも簡単にできる
    - mallinfo(3) (Linux/Glibc)
    - proc/[PID]/statm (Linux)

- 基本後述のresusage使うったほうがよい
    - 事情もある
    - shared libraryだとruntimeは邪魔

---

- libcは楽に触れる
    - Cとの連携の楽さ

```d
extern(C) {
    struct mallinfo_ {
        ...
    }
    mallinfo_ mallinfo();
}
```

---

### DUB Package

- [resusage](http://code.dlang.org/packages/resusage)
    - わりとポータブル(Windows/Linux/FreeBSD)
    - よほど事情がない限り自前で書く必要はない

---

## performance

* GC
* memcpy(3)

---

### GC

[ガベージコレクション](http://www.kmonos.net/alang/d/garbage.html)

> モダンなGCは、過去の遅いものより遙かに発展しています。 世代型のコピーGCには、 昔のマーク＆スイープアルゴリズムの非効率さはありません。
> モダンなGCはヒープの詰め直しを行います。 これによってプログラムが活発に参照するページの数を減らし、 キャッシュヒット率を高め、 スワッップ回数が減ります。

---

#### そんなうまいはなしはなかった。。

- Mark and Sweep / Stop The World
- concurrentとかcopyingとかgenerationalとかない

オリジナルから文言が消えてる! http://dlang.org/spec/garbage.html

---

#### conservative GC

- いわゆる保守的GC
    - ポインタっぽいやつだったらmarkしとこw
- オブジェクトサイズによってPoolを用意
    - デブは電車に乗るな
    - Poolもまた何個かある

---

#### できること

- それほど思いつかない...
- Out-of-Band GCはvibe.dには悪手
    - 効果ない上に全体のスループットは劣化
- jemalloc/tcmalloc試すとか？
    - でもpoolの仕組みはすでにあるしな...

---

#### Manual GC

- GC Configで切り替え可能

`$ ./gctuning "--DRT-gc:manual gcopt=profile:2 minPoolSize:16"`

- 薄いインターフェースとメモリエラー処理だけ提供
    - 自前で頑張る人向け

---

### memcpy(3)

- コピー減らすのは常套手段
    - string連結とかしないでstd.array.appender使うとか
