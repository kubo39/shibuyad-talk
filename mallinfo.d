import std.stdio;

version(CRuntime_Glibc):

extern(C)
{
   struct mallinfo_
    {
        int arena;
        int ordblks;
        int smblks;
        int hblks;
        int hblkhd;
        int usmblks;
        int fsmblks;
        int uordblks;
        int fordblks;
        int keepcost;
    }

    mallinfo_ mallinfo();
}

void main()
{
    auto r = mallinfo();
    r.writeln;
}
