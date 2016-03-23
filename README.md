# RubeePass

Ruby KeePass 2.x implementation. Currently it is read-only.

## How to install

```bash
$ gem install rubeepass
```

## Usage

```
$ rpass -h
Usage: rpass [OPTIONS] [kdbx]
    -e, --export=FILE        Export database to file
    -f, --format=FORMAT      Specify format to use when exporting (default: xml)
    -h, --help               Display this help message
    -k, --keyfile=KEYFILE    Use specified keyfile
    -p, --password=PASSWORD  Use specified password (will prompt if not provided)
    -t, --timeout=TIMEOUT    Clipboard timeout

FORMATS
	gzip
	xml

$ rpass keepass.kdbx
Enter password:
rpass:/> help
COMMAND    DESCRIPTION
-------    -----------
?          Show helpful information for a command or commands
bye        Quit
cat        Show group/entry contents (showall includes passwords)
cd         Change to new group
clear      Clear the screen
cls        Clear the screen
copy       Copy specified field to the clipboard
cp         Copy specified field to the clipboard
dir        List groups and entries in current group
echo       Echo specified field to stdout
exit       Quit
help       Show helpful information for a command or commands
hist       Show history or execute commands from history
history    Show history or execute commands from history
ls         List groups and entries in current group
pwd        Show path of current group
q          Quit
quit       Quit
show       Show group/entry contents (showall includes passwords)
showall    Show group/entry contents (showall includes passwords)
```

## Links

- [Homepage](https://mjwhitta.github.io/rubeepass)
- [Source](https://gitlab.com/mjwhitta/rubeepass)
- [Mirror](https://github.com/mjwhitta/rubeepass)
- [RubyGems](https://rubygems.org/gems/rubeepass)

## TODO

- Better README
- RDoc
- Write/Modify KeePass 2.x data
