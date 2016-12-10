import std.stdio;

string appendString()
{
    string s;
    foreach (i ; 0 .. 10e7)
    {
        s ~= "s";
    }
    return s;
}

void main()
{
    auto s = appendString();
}
