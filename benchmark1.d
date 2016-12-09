import std.array;  // appender
import std.conv : to;
import std.datetime;  // benchmark, Duration
import std.stdio;  // writeln

int n = 10_000;

string makeSlice()
{
    string arr;
    foreach(i; 0 .. n)
        arr ~= "D言語!";
    return arr;
}

string makeSliceOpt()
{
    auto arr = appender!string();
    foreach(i; 0 .. n)
        arr.put("D言語!");
    return arr.data;
}

void main()
{
    auto results = benchmark!(makeSlice, makeSliceOpt)(100);
    foreach (r; results)
        r.to!Duration.writeln;
/*
$ shibuyad-talk% rdmd benchmark1.d
74 ms, 173 μs, and 9 hnsecs
41 ms, 427 μs, and 2 hnsecs
 */
}
