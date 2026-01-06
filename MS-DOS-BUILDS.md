# Building a Standalone Executable for MS-DOS

This file is a reminder for the author, not part of any documentation relevant
for end users.

## Install Strawberry Perl

MS-DOS ships without Perl. A recent Perl can be installed from
https://strawberryperl.com/.

## Start the Crap Shell

This is called `cmd.exe` and can be found with the Spotlight Search.

## Install `pp`

The program `pp` is part of `PAR-Packer`:

```shell
cpanm App::Packer::PAR
```

It should be preinstalled with Strawberry Perl

## Download the Release from CPAN

Either, the release has to be downloaded from CPAN, or `Dist::Zilla` has
to be installed so that a release can be built on the MS-DOS box.

## Build the Executable

Inside the release (make sure that `expand-macros` was run!), type this into
the crap shell:

```shell
pp --lib=lib --output=plisco.exe .\\bin\\plisco
```

Make sure to use backward slashes and add the filename extention `.exe`!

## SCP the Executable Image

For whatever reason, the executable `plisco.exe` cannot be uploaded to GitHub
from the MS-DOS box. Copy it with `scp` to a regular machine, and upload it
from there.
