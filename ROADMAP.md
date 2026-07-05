# Roadmap

This branch focuses on improving `mkmf-lite` without turning it into stdlib
`mkmf`. The guiding rule is to add clearer extension points and better
diagnostics while preserving the small public API that existing callers use.

## Released

### 0.8.0 - Portability Foundation

Released 29-Jun-2026.

* Removed implicit Linux-style library flags from compiler probes.
* Replaced shell-built compiler command strings with argv-style execution.
* Used per-probe temporary directories instead of shared `conftest.c` and
  `conftest.exe` files in `Dir.tmpdir`.
* Avoided global `Dir.chdir` during probe compilation.
* Captured compiler diagnostics internally.
* Improved support for include directories with spaces.
* Added FreeBSD CI coverage.

## 0.9.0 - C Probe Correctness

Improve the generated C probes first, keeping the Ruby API stable and avoiding
changes that could surprise existing callers.

### Generated C Types

Improve generated C for sizes, offsets, and stricter compilers.

Status: Done.

* [x] Print `sizeof` results using `size_t` and `%zu`.
* [x] Print `offsetof` results using `size_t` and `%zu`.
* [x] Avoid casting sizes and offsets down to `int`.
* [x] Review `check_valueof` output formatting for constants wider than `int`.
* [x] Keep return values as Ruby integers.

### Function Probes

Review function detection under stricter C modes.

* Avoid relying on implicit declarations.
* Avoid old-style function assumptions where practical.
* Keep support for checking functions with and without caller-provided headers.
* Preserve the current boolean behavior of `have_func`.

### Compile-Only Probes

Prefer compile-time checks where a probe only needs success or failure.

Status: Done.

* [x] Consider compile-time assertions for struct member checks.
* [x] Keep generated source small and readable for diagnostics.
* [x] Avoid adding platform-specific C unless no portable form exists.

### Diagnostics

Make failed probes easier to understand without printing unexpected output.

* Store the last compile command, stdout, stderr, exit status, and generated C
  source for inspection.
* Add a public diagnostics reader with a small stable shape.
* Keep normal boolean probes quiet by default.
* Improve raised errors from `check_valueof`, `check_sizeof`, and
  `check_offsetof` with captured compiler output.

### Tests

Broaden tests around generated C, failure modes, and platform config.

* [x] Add specs for `sizeof` and `offsetof` values that should not be truncated.
* [x] Add specs for generated compiler/linker arguments.
* [x] Test library names with and without a leading `lib` prefix.
* [x] Test parallel probe invocations.
* Add mocked `RbConfig` coverage for Linux, macOS, FreeBSD, Windows/MSVC, and
  JRuby.
* Add specs for captured diagnostics from failed probes.

### Documentation

Document the portability model and diagnostic behavior.

Status: Done.

* [x] Explain that probes compile tiny C programs using Ruby's configured compiler.
* [x] Clarify how `mkmf-lite` differs from stdlib `mkmf`.
* [x] Add FFI-oriented examples for common Unix-like use cases.
* [x] Document memoization behavior and how it interacts with probe inputs.

## Later

### API Options

Keyword arguments may be useful, but they should wait until the lower-level
probe behavior is settled and the compatibility tradeoffs are clearer.

* Add `include_dirs:` as a keyword alternative to positional include directory
  arguments.
* Add `lib_dirs:` for library search paths.
* Add `cflags:` for extra compile flags.
* Add `ldflags:` for extra link flags.
* Keep existing positional forms compatible.
* Make option handling consistent across `have_header`, `have_func`,
  `have_library`, `have_struct_member`, `check_valueof`, `check_sizeof`, and
  `check_offsetof`.

Example target API:

```ruby
have_header('foo.h', include_dirs: ['/usr/local/include'])
have_library(
  'foo',
  'foo_init',
  headers: ['foo.h'],
  lib_dirs: ['/usr/local/lib'],
  cflags: ['-D_GNU_SOURCE']
)
```

### Configuration

Consider a small configuration API if repeated keyword arguments become noisy.

Status: Done.

* [x] Evaluate `Mkmf::Lite.configure` for global defaults.
* [x] Support compiler, include directories, library directories, compile flags,
  and link flags as possible defaults.
* [x] Make configuration interaction with memoized probe results explicit.

### 1.0.0 - Stable Contract

Finalize the behavior expected by downstream users.

* Document the supported public API and compatibility expectations.
* Document compiler selection, probe memoization, error handling, and platform
  support.
* Keep the library focused on lightweight compile/link probes rather than
  becoming a replacement for stdlib `mkmf`.

### Dependency Reduction

Reducing dependencies is useful, but should not distract from the 0.9 API work.

* Remove `ptools` if it is only needed for `File.which`.
* Replace `File.which` with a small internal executable lookup based on
  `ENV['PATH']`.
* Reevaluate `memoist` after the probe and command execution behavior is stable.
