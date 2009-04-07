# Tape - Tape stuff to the Web

Tape is a simple Web server which will serve up a directory of files
and do simple proxying.  It is quite handy when developing Web
applications that do not depend on application servers.

## Installation and Dependencies

Tape is built on top of Python and Twisted.  It should work on
versions of Twisted from 2.5 onward.  If you have OS X, you already
have both of these.

To install Tape, place the `tape` executable somewhere in your path.

## Using Tape

1. Find a directory you wish to serve.
2. Type `tape`
3. Browse to [http://localhost:8273] to see the result.

### Proxies

One of the best things about Tape is that it will reverse proxy other
things easily.  This is quite handy for applications which must make
AJAX connections because of JavaScript's Same Origin Policy (SOP).

For example, if you are testing a JavaScript XMPP application, you
will need to proxy the connection manager like so:

    tape -P /xmpp-httpbind=http://localhost:5280/xmpp-httpbind

Now your normal files and your reverse proxies are all taken care of
without ever touching Apache or Nginx configuration files!

### Configuration Files

Tape allows you to override its configuration in several ways.  It
will look at things in order, and options set in later steps override
previous ones.

1. It checks ~/.taperc
2. It checks .taperc (in the current directory)
3. It checks the configuration file given on the commandline with `-c`
4. It checks all the command line options

### `taperc` Files

Please see `taperc.example` to see how taperc files are constructed.

## License

This code is copyright (c) 2009 by Jack Moffitt <jack@metajack.im> and
is available under the [GPLv3](http://www.gnu.org/licenses/gpl.html).
See `LICENSE.txt` for details.
