
# Optional packages


* For CMEMS data, you need optionally the python package `copernicusmarine` ([installation instructions](https://pypi.org/project/copernicusmarine/)).
For example:

```bash
python3 -m pip install copernicusmarine
```

Normally you will see the warning `WARNING: The script motuclient is installed in '.../.local/bin' which is not on PATH. Consider adding this directory to PATH`.
You need to add the following line to the file `.bashrc` located in your home directory (at the end of this file on a separate line):

```
export PATH="$HOME/.local/bin:$PATH"
```

In a terminal execute the following so that this change takes effect:

```bash
source ~/.bashrc
```

* Check the `copernicusmarine` (it may return `vUnknown`, but it should not return `No module named copernicusmarine`)

```bash
copernicusmarine --version
```
