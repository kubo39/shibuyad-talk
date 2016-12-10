import core.sys.posix.unistd : sleep;

extern(C) void calcHeavy()
{
    sleep(1);
}

extern(C) int main()
{
    calcHeavy();
    return 0;
}
