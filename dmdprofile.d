import core.thread;  // sleep
import std.datetime;

void tooSlowFunction()
{
    Thread.sleep(dur!"msecs"(1000));
}

void main()
{
    tooSlowFunction();
}
