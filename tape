#!/usr/bin/env python
# -*- mode: python -*-


import os
import sys
import urllib
from datetime import datetime
from optparse import OptionParser
from ConfigParser import RawConfigParser

from twisted.application import internet
from twisted.internet import reactor
from twisted.python import log
from twisted.web import server, static, proxy
from twisted.web.resource import NoResource
from twisted.web.util import redirectTo


VERSION = '1.0'
DEFAULT_PORT = 8273 # t-a-p-e... get it?


class TapeSite(server.Site):
    def log(self, request):
        """Log a request's result to stdout, in combined log format."""
        line = '%s - - %s "%s" %d %s "%s" "%s"\n' % (
            request.getClientIP(),
            # request.getUser() or "-", # the remote user is almost never important
            datetime.now(),
            '%s %s %s' % (urllib.quote_plus(request.method),
                          urllib.quote_plus(request.uri),
                          urllib.quote_plus(request.clientproto)),
            request.code,
            request.sentLength or "-",
            urllib.quote_plus(request.getHeader("referer") or "-"),
            urllib.quote_plus(request.getHeader("user-agent") or "-"))
        sys.stdout.write(line)


class DummyResource(static.Data):
    """Placeholder for intermediate path to a proxy."""
    def __init__(self):
        static.Data.__init__(self, 'nothing to see here', 'text/plain')

    def getChild(self, path, request):
        if path == '':
            # dummy is the same as dummy/
            return self
        return static.Data.getChild(self, path, request)


class ProxyResource(proxy.ReverseProxyResource):
    """Wrapper around ReverseProxyResource to add redirect on base access."""
    def getChild(self, path, request):
        if path == '':
            return proxy.ReverseProxyResource(
                self.host, self.port, '/')
        return proxy.ReverseProxyResource.getChild(self, path, request)

    def render(self, request):
        return redirectTo(request.uri + '/', request)


class TapeResource(static.File):
    def __init__(self, config):
        static.File.__init__(self, config.get('server', 'root'),
                             defaultType='text/plain')

        for lurl, rurl in config.items('proxies'):
            # decode the remote url
            try:
                rparts = rurl.split('/', 3)
                if ':' in rparts[2]:
                    rhost, rport = rparts[2].split(':')
                else:
                    rhost, rport = rparts[2], '80'
                if len(rparts) < 4 or rparts[3] == '':
                    rpath = ''
                else:
                    rpath = '/' + rparts[3]
            except:
                print "WARNING: Skipping unparseable remote url: %s" % rurl
                continue

            rproxy = proxy.ReverseProxyResource(rhost, int(rport), rpath)

            # decode the local url
            lparts = filter(lambda x: x != '', lurl.split('/'))
            if len(lparts) == 0:
                print "WARNING: Skipping proxy %s.  Can't proxy at root." % \
                    lurl
                continue

            parent = self
            for p in lparts[:-1]:
                c = parent.getChildWithDefault(p, None)
                if isinstance(c, NoResource):
                    parent.putChild(p, DummyResource())
                    parent = parent.getChildWithDefault(p, None)
                else:
                    parent = c
            parent.putChild(lparts[-1], rproxy)

    def createSimilarFile(self, path):
        """Create similar file for handling children.
        This is needed because we overloaded the constructor.
        """
        return static.File(path, defaultType='text/plain')


def parse_args():
    usage = "usage: %prog [options]"
    version = "%prog " + ("%s" % VERSION)
    parser = OptionParser(usage=usage, version=version)
    parser.add_option('-c', '--config', dest='config', metavar='FILE',
                      help='use FILE for configuration')
    parser.add_option('-p', '--port', dest='port',
                      help='listen on PORT')
    parser.add_option('-r', '--root', dest='root', metavar='DIR',
                      help='use DIR as the document root')
    parser.add_option('-P', '--proxy', dest='proxies', action='append',
                      metavar='LURL=RURL',
                      help='reverse proxy RURL as LURL')
    return parser.parse_args()

def parse_config_files(options):
    """Parse configuration files.
    First ~/.taperc is parsed, then .taperc, then whatever is passed
    via --config.  Finally the command line options are applied.
    """
    config = RawConfigParser()
    config.optionxform = str
    
    # set defaults
    config.add_section('server')
    config.add_section('proxies')
    config.set('server', 'port', '8273')
    config.set('server', 'root', '.')

    files = ['%s/.taperc' % os.environ['HOME'], '.taperc']
    if options.config:
        files.append(options.config)

    config.read(files)

    # update config with command line options
    if options.root:
        config.set('server', 'root', options.root)
    if options.port:
        config.set('server', 'port', options.port)
    if options.proxies:
        for p in options.proxies:
            lurl, rurl = p.split('=', 1)
            config.set('proxies', lurl, rurl)

    return config

def print_banner(config):
    print "tape %s starting..." % VERSION
    print "  listening on port %s" % config.get('server', 'port')
    print "  serving from %s" % config.get('server', 'root')
    proxies = config.items('proxies')
    if proxies:
        print "  proxying"
        for lurl, rurl in proxies:
            print "    %s under %s" % (rurl, lurl)
    print

def main():
    (options, args) = parse_args()
    config = parse_config_files(options)

    print_banner(config)

    # start it up
    site = TapeSite(TapeResource(config))
    service = internet.TCPServer(int(config.get('server', 'port')), site)
    service.startService()
    reactor.run()

if __name__ == '__main__':
    main()
