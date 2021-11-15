class foobar
{
    int i;

public:
    foobar()
    {
        i = 100;
    }

    void inc()
    {
        i++;
    }
};

foobar foo;

int main()
{
    foo.inc();
    for (;;);
}

