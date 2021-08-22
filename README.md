## Summary
A light version of mkmf designed for use within programs.

## Installation
`gem install mkmf-lite`

## Adding the trusted cert
`gem cert --add <(curl -Ls https://raw.githubusercontent.com/djberg96/mkmf-lite/main/certs/djberg96_pub.pem)`

## Prerequisites
A C compiler somewhere on your system.

## Synopsis
```
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

## Known Issues
You may see this warning from JRuby 1.4.x and earlier:

warning: Useless use of a variable in void context.

You can ignore these (or, upgrade your Jruby).

## License
Apache-2.0

## Copyright
(C) 2010-2020 Daniel J. Berger
All Rights Reserved

## Warranty
This library is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantability and fitness for a particular purpose.

## Author
Daniel J. Berger
