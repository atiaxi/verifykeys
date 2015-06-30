verifykeys.rb is a command-line tool for cassandra that takes a list of
partition keys and verifies that there is at least one row for each key.
Its intended use is in verifying that a backup recovery is probably complete.

# Installation

The only requirement that verifykeys.rb has is the
[cassandra driver](https://github.com/datastax/ruby-driver) - if that is
installed, then verifykeys.rb can be placed and executed anywhere.

# Usage

```
Usage: verifykeys.rb [options] [file...]
    -v, --verbose                    Print verification status of all keys
    -d, --nodes node1,node2,node3    Connect to the (comma separated) list of nodes
    -p, --port PORT                  Connect to the given port
    -k, --keyspace KS                Check against the given keyspace
    -t, --table TABLE                Check against the given table
    -r, --partition COLUMN           Use the given column as the partition key
    -q, --quick                      Exit immediately if a key is not found
    -h, --help                       Show this message
```

## Some examples would be nice

At its most basic:

`verifykeys.rb table_load_test.primary_ascii.keys`

The given file is a newline separated list of keys in hexadecimal format
(see 'Generating key lists with sstable2json', below).  The keyspace and
table to use will be inferred from the filename but can be specified
using the `-k` and `-t` options if the filename would be incorrect or you
instead want to provide keys via STDIN.

The `-r` option is used for the partition key column and is 'name' by default.
If this is not the name of your partition key column, you will need to change
it.  For example, given this schema:

```
CREATE TABLE some_keyspace.some_table(
  some_key TEXT PRIMARY KEY,
  some_value TEXT
)
```

Where the keys have been saved to a file named `keys.txt`, the verification
script invocation command would look more like:

`verifykeys.rb keys.txt -k some_keyspace -t some_table -r some_key`

## Generating key lists with sstable2json

If you do not want to create a list of keys by hand (and you probably don't),
you can use the `sstable2json` utility to create them:

`sstable2json -e some_keyspace-some_table-jb-1-Data.db > some_keyspace.some_table.keys`

# Limitations

Currently, the script assumes:

* The key list is in hex, as generated by sstable2json versions 2.0 and below.

* The keys themselves are strings.

* The keys are not composite keys.
