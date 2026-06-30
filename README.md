[![Ruby](https://github.com/djberg96/mkmf-lite/actions/workflows/ruby.yml/badge.svg)](https://github.com/djberg96/mkmf-lite/actions/workflows/ruby.yml)

## Summary
A light version of mkmf designed for use within programs.

## Installation
`gem install mkmf-lite`

## Adding the trusted cert
`gem cert --add <(curl -Ls https://raw.githubusercontent.com/djberg96/mkmf-lite/main/certs/djberg96_pub.pem)`

## Prerequisites
A C compiler somewhere on your system. `mkmf-lite` uses the compiler Ruby was
configured with when possible, falling back to common compiler names on your
`PATH`.

## Synopsis
```ruby
require 'mkmf/lite'

class System
  extend Mkmf::Lite

  HAVE_PW_NAME = have_struct_member('struct passwd', 'pw_name', 'pwd.h')

  def some_method
    if HAVE_PW_NAME
      # Do something
    end
  end
end
```

## Description
The mkmf library that ships as part of the Ruby standard library is not
meant for use as an internal library. It's strictly designed for building
C extensions. It's huge, its methods sit in a global namespace, it contains
many methods you don't care about, and it emits stuff to $stdout that cannot
easily be disabled. Also, the source code is monstrous.

The mkmf-lite library is a module, it's small, and it's designed to be mixed
into classes. It contains a handful of methods that, most likely, will be
used in conjunction with FFI. Also, the source code is quite readable.

It does not package C extensions, nor generate a log file or a Makefile. It
does, however, require that you have a C compiler somewhere on your system.

## Portability model
Each probe generates a tiny C program in a per-probe temporary directory and
asks Ruby's configured compiler to compile it. Boolean probes return whether
that compile or link step succeeded. Value probes compile and run a small
program that prints the requested integer value.

The generated source is intentionally small and portable. `mkmf-lite` avoids
assuming Linux-specific libraries or global temporary filenames, and it passes
compiler arguments as argv-style command parts so paths with spaces can work.

Unlike stdlib `mkmf`, this library does not create a `Makefile`, does not build
an extension, does not write an `mkmf.log`, and keeps its API inside
`Mkmf::Lite` instead of relying on top-level methods.

## Diagnostics
Boolean probes such as `have_header`, `have_func`, `have_library`, and
`have_struct_member` are quiet by default and return `true` or `false`.

Value probes such as `check_valueof`, `check_sizeof`, and `check_offsetof`
raise `StandardError` if their generated C cannot be compiled. The exception
message includes the compiler command, compiler stderr, and generated source so
you can see what failed without hunting for a separate log file.

## FFI examples
Use `mkmf-lite` to decide which declarations are safe to expose through FFI:

```ruby
require 'ffi'
require 'mkmf/lite'

module LibC
  extend FFI::Library
  extend Mkmf::Lite

  ffi_lib FFI::Library::LIBC

  attach_function :getpid, [], :int if have_func('getpid', 'unistd.h')
end
```

You can also use it to size native structs:

```ruby
class StatLayout
  extend Mkmf::Lite

  STAT_SIZE = check_sizeof('struct stat', 'sys/stat.h')
  UID_OFFSET = check_offsetof('struct stat', 'st_uid', 'sys/stat.h')
  HAS_BIRTHTIME = have_struct_member('struct stat', 'st_birthtime', 'sys/stat.h')
end
```

For libraries installed outside the compiler's default include path, pass
include directories to probes that accept them:

```ruby
class LocalHeader
  extend Mkmf::Lite

  HAVE_FOO = have_header('foo.h', '/usr/local/include')
  FOO_VERSION = check_valueof('FOO_VERSION', 'foo.h', '/usr/local/include')
end
```

## Memoization
As of version 0.6.0, public probe results are memoized for the lifetime of the
object that extends `Mkmf::Lite`. The method arguments are part of the cache
key, so `have_header('foo.h')` and `have_header('foo.h', '/usr/local/include')`
are distinct checks.

This fits the normal use case where compiler configuration, headers, and system
libraries do not change while the Ruby process is running. If you need to probe
again after changing the environment, create a new object or restart the
process.

## Known Issues
JRuby may emit warnings on some platforms.

## License
Apache-2.0

## Copyright
(C) 2010-2025 Daniel J. Berger
All Rights Reserved

## Warranty
This library is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantability and fitness for a particular purpose.

## Author
Daniel J. Berger
