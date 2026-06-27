# Roadmap

This branch focuses on making `mkmf-lite` more platform-neutral, safer to use
inside applications, and easier to validate across Unix-like systems. The main
goal is to avoid FreeBSD-specific special cases where a more general portability
improvement would solve the same problem.

## 0.8.0 - Portability Foundation

Keep the public API stable and harden the existing implementation.

* Replace hard-coded default libraries in `cpp_libraries`.
* Stop assuming Linux-style `rt`, `dl`, `crypt`, and `m` availability.
* Fix the clang branch that currently emits `-Lrt`, `-Ldl`, `-Lcrypt`, and
  `-Lm`; these are library search path flags, not library link flags.
* Prefer Ruby's `RbConfig` values where they are appropriate, and only add
  explicit libraries when a probe requires them.
* Use a per-probe temporary directory instead of shared `conftest.c` and
  `conftest.exe` files in `Dir.tmpdir`.
* Avoid global `Dir.chdir` during probe compilation when practical.
* Replace shell-built compiler command strings with argv-style execution.
* Capture compiler diagnostics internally without emitting unwanted output.
* Add FreeBSD CI coverage, likely through Cirrus CI or a GitHub Actions
  FreeBSD runner.

## 0.9.0 - API Improvements

Add clearer extension points while preserving the existing positional API.

* Add keyword options for include directories, library directories, compile
  flags, and link flags.
* Consider examples such as:

  ```ruby
  have_header('foo.h', include_dirs: ['/usr/local/include'])
  have_library(
    'foo',
    'foo_init',
    headers: ['foo.h'],
    lib_dirs: ['/usr/local/lib']
  )
  ```

* Add access to the last failed compile command and diagnostics.
* Consider a small configuration API for global defaults such as compiler,
  include paths, library paths, and extra flags.
* Keep memoized public probes, but document when memoization applies and how
  callers should think about process lifetime.

## 1.0.0 - Stable Contract

Finalize the behavior expected by downstream users.

* Document the supported public API and compatibility expectations.
* Remove unnecessary runtime dependencies where feasible.
* Document compiler selection, probe memoization, error handling, and platform
  support.
* Keep the library focused on lightweight compile/link probes rather than
  becoming a replacement for stdlib `mkmf`.

## C Probe Correctness

These improvements can land in the earliest release where they fit cleanly.

* Print `sizeof` results using `size_t` and `%zu`.
* Print `offsetof` results with an appropriate unsigned size format.
* Avoid casting sizes and offsets down to `int`.
* Review function probes under stricter C modes, where implicit declarations
  and old-style function assumptions may fail.
* Consider compile-time assertions for probes that only need success or failure.

## Dependency Reduction

Reducing dependencies is useful, but should not distract from the portability
foundation.

* Remove `ptools` if it is only needed for `File.which`.
* Replace `File.which` with a small internal executable lookup based on
  `ENV['PATH']`.
* Reevaluate `memoist` after the probe and command execution behavior is stable.

## Test Coverage

The test suite should exercise command construction and failure modes, not only
successful local probes.

* Add specs for generated compiler/linker arguments.
* Test include and library directories containing spaces.
* Test library names with and without a leading `lib` prefix.
* Test parallel probe invocations to catch temporary file collisions.
* Add mocked `RbConfig` coverage for Linux, macOS, FreeBSD, Windows/MSVC, and
  JRuby.
* Add a regression test proving clang does not receive bogus `-Lrt`-style
  flags.

## Documentation

Documentation should make the portability model explicit.

* Explain that probes compile tiny C programs using Ruby's configured compiler.
* Clarify how `mkmf-lite` differs from stdlib `mkmf`.
* Add FFI-oriented examples for common Unix-like use cases.
* Document how to pass include and library paths for ports-installed libraries,
  especially `/usr/local/include` and `/usr/local/lib` on FreeBSD.
