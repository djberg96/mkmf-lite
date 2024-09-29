## 0.7.1 - 29-Sep-2024
* Skip adding compiler switches for JRuby, which chokes on them for some reason.

## 0.7.0 - 13-Sep-2024
* Append typical library switches to the compiler command. There was a private
  method already in the code but I wasn't using it.
* Append DEFS if present in your RbConfig options. This was mainly to ensure
  that FILE_OFFSET_BITS is passed, if present, but there could be other
  macros in theory.

## 0.6.0 - 26-Sep-2023
* Added the memoist gem and memoized the results of all public methods since
  the odds of them changing between calls is basically zero.

## 0.5.2 - 24-Mar-2023
* Lots of rubocop updates and minor cleanup, including the addition of
  rubocop and rubocop-rspec as deve dependencies.
* Deprecation warning fixes (actually bug fixes for Ruby 3.2).

## 0.5.1 - 18-Dec-2020
* Switch docs to markdown format because github isn't rendering rdoc properly.

## 0.5.0 - 6-Dec-2020
* Added the check_valueof method.

## 0.4.2 - 31-Aug-2020
* Did I say I didn't need ptools? Well I was wrong. It's back.

## 0.4.1 - 31-Aug-2020
* Removed the ptools dependency, just use IO::NULL.

## 0.4.0 - 4-Jul-2020
* Replaced test-unit with rspec, rewrote the tests, and made relevant
  changes to the gemspec, etc.
* Pinned the ptools version to 1.3.x.

## 0.3.2 - 19-Mar-2020
* Properly include a LICENSE file as per the Apache-2.0 license.

## 0.3.1 - 11-Dec-2019
* Added .rdoc extension to various text files so that they render more nicely
  on github.

## 0.3.0 - 6-Jan-2019
* Changed license to Apache-2.0.
* Replaced class variables with methods.
* Updated cert.

## 0.2.6 - 6-Sep-2015
* Added an mkmf-lite.rb file for convenience.
* Assume Rubygems 2.x.
* This gem is now signed.

## 0.2.5 - 2-Oct-2014
* The CC command for mingw now defaults to searching your path rather than
  relying on an environment variable because it wasn't trustworthy.
* Updated the gem:install task for Rubygems 2.x.

## 0.2.4 - 7-Mar-2013
* The have_header method now accepts an optional list of directories to search.

## 0.2.3 - 25-Apr-2012
* No longer assumes mingw/gcc on Windows. Now passes all tests with a
  version of Ruby compiled with MSVC++.
* Eliminate Config vs RbConfig warnings in 1.9.3.
* The stdout stream is now temporarily closed in places where it could
  result in unwanted output.
* Upgraded test-unit prerequisite to 2.4.0 or later.

## 0.2.2 - 6-Dec-2011
* Added the check_sizeof method.
* If CONFIG['COMMON_HEADERS'] is blank then stdio.h and stdlib.h are
  used instead. On MS Windows the windows.h header is also used.

## 0.2.1 - 21-Jan-2011
* Minor platform detection adjustments for MS Windows.

## 0.2.0 - 8-Jun-2010
* Now works properly with JRuby (though it still requires a compiler
  somewhere on your system).

## 0.1.0 - 24-May-2010
* Initial release.
