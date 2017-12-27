<div class="hidden-warning"><a href="https://docs.haskellstack.org/"><img src="https://rawgit.com/commercialhaskell/stack/master/doc/img/hidden-warning.svg"></a></div>

# Maintainer guide

## Next release:

* Don't upgrade stack.yaml to lts 10 until after v1.7 has been released (therwise will prevent `stack upgrade` from source working for people on older versions)
* @@@ for prerelease/release candidate, make a `vX.Y.Z` (minor version) branch and enable RTFD for it so that doc links (which ignore patchlevel) work
* Add SHA256 checksums for bindists
* Also sign/checksum sdists?
* Create release candidate process (maybe switch to GHC-style versioning)
* Maybe drop 32-bit CentOS 6 bindists, since GHC 8.2.1 seems to have dropped them.
* Replace non-static Linux bindists with static (but keep old links active so
  links don't break and 'stack upgrade' in old versions still work)
* @@@ be careful with Alpine VM image, might want to avoid re-provisioning it in case new GHC package is released and that breaks the release process. (see https://github.com/alpinelinux/aports/pull/2042)
* @@@ note: windows exe signing certificate expires Thu Sep 21 21:52:29 2017
    * https://stackoverflow.com/questions/12311203/how-to-pass-the-smart-screen-on-win8-when-install-a-signed-application/28359323#28359323
    * https://security.stackexchange.com/questions/139347/smart-screen-filter-still-complains-despite-i-signed-the-executable-why
    * https://github.com/mintty/wsltty/issues/32
* @@@ openBSD binaries, if building with GHC 8.2.1 (now that openbsd GHC bindists exist)
* @@@ might have alpine 32-bit GHC available too (see https://github.com/alpinelinux/aports/pull/2042#issuecomment-320137857) for static 32-bit builds.  also try bindists in https://github.com/redneb/ghc-alt-libc
* @@@ maybe announce fully phasing out ubuntu/centos packages?
* @@@ put back on stackage

## Version scheme

* Versions with an _even_ third component (e.g. 1.6.2 and 1.7.0) are unreleased development versions
* Versions with an _odd_ third component (e.g. 1.6.1 or 1.7.3) and released versions
* Pre-release and release candidate binaries will be released with an even third component and the date as the fourth component (e.g. 1.6.0.20171129)
* All branches _except_ `release` (which matches exactly the most recent release) must have an even third component (development)
* Branches other than `stable` and `release` will always have a `0` third component (e.g. 1.7.0).

## Pre-release steps

* Check for any P0 and P1 issues
* Check for un-merged pull requests
* Ensure `release` and `stable` branches merged to `master`
* Check compatibility with latest Stackage snapshots
    * `stack-*.yaml` (where `*` is not `nightly`), __including the ones in
      subdirectories__: bump to use latest LTS minor
      version (be sure any extra-deps that exist only for custom flags have
      versions matching the snapshot)
    * Check for any redundant extra-deps
    * Run `stack --stack-yaml=stack-*.yaml test --pedantic` (replace `*` with
      the actual file)
* Check compatibility with latest nightly stackage snapshot:
    * Update `stack-nightly.yaml` with latest nightly and remove extra-deps (be
      sure any extra-deps that exist only for custom flags have versions
      matching the snapshot)
    * Run `stack --stack-yaml=stack-nightly.yaml test --pedantic`
* Check compatibility with latest Hackage:
    [@@@ export PATH=$(stack --stack-yaml=stack-nightly.yaml path --compiler-bin):$PATH
    [@@@ check for any bounds preventing use of latest packages (note that deprecated packes will show up in this list; ignore those): cabal sandbox delete; stack build --dry-run && cabal sandbox init && cabal update && cabal install --enable-test --enable-bench --dry-run | grep latest]
    [@@@ try building with latest allowed by bounds:
    PATH=$(stack --stack-yaml=stack-nightly.yaml path --compiler-bin):$PATH cabal install --only-dependencies && cabal install --enable-test -f integration-tests
    @@@]
* Ensure integration tests pass on a Windows, macOS, and Linux (Linux
  integration tests are run
  by
  [Gitlab](http://gitlab.fpcomplete.com/fpco-mirrors/stack/pipelines)):
  `stack install --pedantic && stack test --pedantic --flag
  stack:integration-tests`. The actual release script will perform a more
  thorough test for every platform/variant prior to uploading, so this is just a
  pre-check
* In master branch:
    * ChangeLog: rename the "Unreleased changes" section to the new version
* Cut a release candidate branch `rc/vX.Y` from master
* In master branch:
    * package.yaml: bump version to next major (second) component with `.0` third component (e.g. from 1.6.2 to 1.7.0)
    * Changelog: add new "Unreleased changes" section
* In RC branch:
    * Update the ChangeLog:
        * Check for any important changes that missed getting an entry in
          Changelog (`git log origin/stable...HEAD`)
        * Check for any entries that snuck into the previous version's changes
          due to merges (`git diff origin/stable HEAD ChangeLog.md`)
    * Review documentation for any changes that need to be made
        * Search for old Stack version, unstable stack version, and the next
          "obvious" version in sequence (if doing a non-obvious jump), and
          `UNRELEASED` and replace with new version
        * Look for any links to "latest" documentation, replace with version tag
        * Ensure all documentation pages listed in `mkdocs.yaml`
          (`git diff --stat origin/stable..HEAD doc/`)
        * Any new documentation pages should have the "may not be correct for
          the released version of Stack" warning at the top.
    * Update `.github/ISSUE_TEMPLATE.md` to point at the new version.
    * Check for new [FreeBSD release](https://www.freebsd.org/releases/).
    * Check that no new entries need to be added to
      [releases.yaml](https://github.com/fpco/stackage-content/blob/master/stack/releases.yaml),
      [install_and_upgrade.md](https://github.com/commercialhaskell/stack/blob/master/doc/install_and_upgrade.md),
      and
      `README.md`
    * Remove unsupported/obsolete distribution versions from the release process.
        * [Ubuntu](https://wiki.ubuntu.com/Releases)
            * 14.04 EOL 2019-APR
            * 16.04 EOL 2021-APR
        * [CentOS](https://wiki.centos.org/Download)
            * 6 EOL 2020-NOV-30
            * 7 EOL 2024-JUN-30

## Release process

[@@@ FOR A PRE-RELEASE, BE SURE TO ACTIVATE THE TAG IN RTFD SO THAT DOC LINKS WORK -- @@@ ACTUALLY ADD branch for major version since now doc links leave off patchlevel]

See
[stack-release-script's README](https://github.com/commercialhaskell/stack/blob/master/etc/scripts/README.md#prerequisites)
for requirements to perform the release, and more details about the tool.

A note about the `etc/scripts/*-releases.sh` scripts: if you run them from a
different working tree than the scripts themselves (e.g. if you have `stack1`
and `stack2` trees, and run `cd stack1; ../stack2/etc/scripts/vagrant-release.sh`)
the scripts and Vagrantfiles from the
tree containing the script will be used to build the stack code in the current
directory. That allows you to iterate on the release process while building a
consistent and clean stack version.

* package.yaml: bump version to odd last component (e.g. from 1.6.0 to 1.6.1).

* Create a
  [new draft Github release](https://github.com/commercialhaskell/stack/releases/new)
  with tag and name `vX.Y.Z` (where X.Y.Z is the stack package's version), targeting the
  RC branch

* On each machine you'll be releasing from, set environment variable `GITHUB_AUTHORIZATION_TOKEN`.

* On a machine with Vagrant installed:
    * Run `etc/scripts/vagrant-releases.sh`

* On macOS:
    * Run `etc/scripts/osx-release.sh`

* On Windows:
    * Use a short path for your working tree (e.g. `C:\p\stack-release`
    * Ensure that STACK_ROOT, TEMP, and TMP are set to short paths
    * Run `etc\scripts\windows-releases.bat`
    * Release Windows installers. See
      [stack-installer README](https://github.com/borsboom/stack-installer#readme)
      [@@@ copy to `_release` and then use release script to upload sigs and checksums]

* On Linux ARMv7:
    * Run `etc/scripts/linux-armv7-release.sh`

* Build sdist using `stack sdist .`, and upload it to the
  Github release with a name like `stack-X.Y.Z-sdist-0.tar.gz`.
  [@@@ copy to `_release` and then use release script to upload sigs and checksums]

* Use `etc/scripts/sdist-with-bounds.sh` to generate a Cabal spec and sdist with dependency bounds.

* Upload `_release/stack-X.Y.Z-sdist-1.tar.gz` to the Github release.
  [@@@ copy to `_release` and then use release script to upload sigs and checksums]

* Publish Github release. Include the changelog and in the description and use e.g. `git shortlog -s release..HEAD|sed $'s/^[0-9 \t]*/* /'|sort -f` to get the list of contributors.

* Push signed Git tag, matching Github release tag name, e.g.: `git tag -d vX.Y.Z; git tag -s -m vX.Y.Z vX.Y.Z && git push -f origin vX.Y.Z`

* Reset the `release` branch to the released commit, e.g.: `git checkout release && git merge --ff-only vX.Y.Z && git push origin release`

* Update the `stable` branch similarly

* Upload package to Hackage: `stack upload .`

* Make a revision on Hackage using the bounds from `_release/stack-X.Y.Z_bounds.cabal`.

* In the `stable` branch's:
    * package.yaml: bump the version number even third component (e.g. from 1.6.1 to 1.6.2)
    * ChangeLog: Add an "Unreleased changes" section

* Delete the RC branch (locally and on origin)

* Activate version for new release tag on
  [readthedocs.org](https://readthedocs.org/dashboard/stack/versions/), and
  ensure that stable documentation has updated

* Merge any changes made in the RC/release/stable branches to master (be careful about version changes)

* On a machine with Vagrant installed:
    * Make sure you are on the same commit as when `vagrant-release.sh` was run.
    * Set environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`.
      Note: since one of the tools (rpm-s3 on CentOS) doesn't support AWS temporary credentials, you can't use MFA with the AWS credentials (`AWS_SECURITY_TOKEN` is ignored).

    * Run `etc/scripts/vagrant-distros.sh`

* Upload haddocks to Hackage: `etc/scripts/upload-haddocks.sh` (if they weren't auto-built)

* Announce to haskell-cafe@haskell.org, haskell-stack@googlegroups.com,
  commercialhaskell@googlegroups.com mailing lists

* Update fpco/stack-build Docker images with new version

* Keep an eye on the
  [Hackage matrix builder](http://matrix.hackage.haskell.org/package/stack)

* @@@ add back to stackage nightly if fallen out

## Setting up a Windows VM for releases

These instructions are a bit rough, but has the steps to get the Windows machine
set up.

 1. Download VM image:
    https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/mac/

 2. Launch the VM using Virtualbox and the image downloaded

 3. Adjust settings:
    * Number of CPUs: at least half the host's
    * Memory: at least 3 GB
    * Video RAM: the minimum recommended by Virtualbox
    * Enable 3D and 2D accelerated mode (this makes programs with lots of console output much faster)
    * Enabled shared clipboard (in VM window, Devices->Shared Clipboard->Both Directions)

 4. [@@@ TODO] Install the VMware guest additions, and reboot

 5. [@@@ TODO] In **Settings**->**Update & Security**->**Windows Update**->**Advanced options**:
     * Change **Choose how updates are installed** to **Notify to schedule restart**
     * Check **Defer upgrades**

 6. Optional (for convenience): Configure a shared folder for your home directory on the host, and mount it on Z:

 7. [@@@ TODO] Install Windows SDK (for signtool):
    http://microsoft.com/en-us/download/confirmation.aspx?id=8279

 8. Install msysgit: https://msysgit.github.io/

 9. Install nsis-2.46.5-Unicode-setup.exe from http://www.scratchpaper.com/

10: Install Stack using the Windows 64-bit installer

11. Visit https://hackage.haskell.org/ in Edge to ensure system has correct CA
    certificates

12. [@@@ TODO] Obtain a code signing certificate.
    Double click it in explorer and import it.  If you do not have a signing certificate,
    there are various CAs that will issue them.  As of this writing, the least expensive option is an [Open Source Code Signing certificate from Certum](https://www.certum.eu/certum/cert,offer_en_open_source_cs.xml)

13. Run in command prompt:

        md C:\p
        md C:\p\tmp
        cd \p

14. Create `C:\p\env.bat`:

        SET TEMP=C:\p\tmp
        SET TMP=C:\p\tmp
        SET PATH="c:\Program Files\Git\usr\bin";"C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin";%PATH%

15. Run `C:\p\env.bat` (do this every time you open a new command prompt)

16. [@@@ TODO] Import the `dev@fpcomplete.com` (0x575159689BEFB442) GPG secret key

17. Run in command prompt (adjust the `user.email` and `user.name` settings):

        stack --install-ghc install cabal-install
        git config --global user.email manny@fpcomplete.com
        git config --global user.name "Emanuel Borsboom"
        git config --global push.default simple
        git config --global core.autocrlf true
        git clone https://github.com/commercialhaskell/stack.git stack-release
        git clone https://github.com/borsboom/stack-installer.git

## Setting up an ARM VM for releases

These instructions assume the host system is running macOS. Some steps will vary
with a different host OS.

### Install qemu on host

    brew install qemu

### Install fuse-ext2

    brew install e2fsprogs m4 automake autoconf libtool && \
    git clone https://github.com/alperakcan/fuse-ext2.git && \
    cd fuse-ext2 && \

Add `m4_ifdef([AM_PROG_AR], [AM_PROG_AR])` to the `configure.ac` after
`m4_ifdef([AC_PROG_LIB],[AC_PROG_LIB],[m4_warn(portability,[Missing AC_PROJ_LIB])])`
line.

    PKG_CONFIG_PATH="$(brew --prefix e2fsprogs)/lib/pkgconfig" \
        CFLAGS="-idirafter/$(brew --prefix e2fsprogs)/include -idirafter/usr/local/include/osxfuse" \
        LDFLAGS="-L$(brew --prefix e2fsprogs)/lib" \
        ./configure

### Create VM and install Debian in it

    wget http://ftp.de.debian.org/debian/dists/jessie/main/installer-armhf/current/images/netboot/initrd.gz && \
    wget http://ftp.de.debian.org/debian/dists/jessie/main/installer-armhf/current/images/netboot/vmlinuz && \
    wget http://ftp.de.debian.org/debian/dists/jessie/main/installer-armhf/current/images/device-tree/vexpress-v2p-ca9.dtb && \
    qemu-img create -f raw armdisk.raw 15G && \
    qemu-system-arm -M vexpress-a9 -cpu cortex-a9 -kernel vmlinuz -initrd initrd.gz -sd armdisk.raw -append "root=/dev/mmcblk0p2" -m 1024M -redir tcp:2223::22 -dtb vexpress-v2p-ca9.dtb -append "console=ttyAMA0,115200" -serial stdio

Now the Debian installer will run. Don't use LVM for partitioning (it won't
boot), and add at least 4 GB swap during installation.

### Get boot files after install

Adjust the disk number `/dev/disk3` below to match the output from `hdiutil attach`.

    hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount armdisk.raw && \
    sudo mkdir -p /Volumes/debarm && \
    sudo fuse-ext2 /dev/disk3s1 /Volumes/debarm/ && \
    sleep 5 && \
    cp /Volumes/debarm/vmlinuz-3.16.0-4-armmp . && \
    cp /Volumes/debarm/initrd.img-3.16.0-4-armmp . && \
    sudo umount /Volumes/debarm && \
    hdiutil detach /dev/disk3

### Boot VM

Adjust `/dev/mmcblk0p3` below to the root partition you created during installation.

    qemu-system-arm -M vexpress-a9 -cpu cortex-a9 -kernel vmlinuz-3.16.0-4-armmp -initrd initrd.img-3.16.0-4-armmp -sd armdisk.raw -m 1024M -dtb vexpress-v2p-ca9.dtb -append "root=/dev/mmcblk0p3 console=ttyAMA0,115200" -serial stdio -redir tcp:2223::22

### Setup rest of system

Log onto the VM as root, then (replace `<<<USERNAME>>>` with the user you set up
during Debian installation):

    apt-get update && \
    apt-get install -y sudo && \
    adduser <<<USERNAME>>> sudo

Now you can SSH to the VM using `ssh -Ap 2223 <<<USERNAME>>>@localhost` and use `sudo` in
the shell.

### Install build tools and dependencies packages

    sudo apt-get install -y g++ gcc libc6-dev libffi-dev libgmp-dev make xz-utils zlib1g-dev git gnupg

### Install clang+llvm

NOTE: the Debian jessie `llvm` package does not work (executables built with it
just exit with "schedule: re-entered unsafely.").

The version of LLVM needed depends on the version of GHC you need.

#### GHC 8.0.2 (the standard for building Stack)

    wget http://llvm.org/releases/3.7.1/clang+llvm-3.7.1-armv7a-linux-gnueabihf.tar.xz && \
    sudo tar xvf clang+llvm-3.7.1-armv7a-linux-gnueabihf.tar.xz -C /opt

Run this now and add it to the `.profile`:

    export PATH="$HOME/.local/bin:/opt/clang+llvm-3.7.1-armv7a-linux-gnueabihf/bin:$PATH"

#### GHC 7.10.3

    wget http://llvm.org/releases/3.5.2/clang+llvm-3.5.2-armv7a-linux-gnueabihf.tar.xz && \
    sudo tar xvf clang+llvm-3.5.2-armv7a-linux-gnueabihf.tar.xz -C /opt

Run this now and add it to the `.profile`:

    export PATH="$HOME/.local/bin:/opt/clang+llvm-3.5.2-armv7a-linux-gnueabihf/bin:$PATH"

### Install Stack

#### Binary

Get an [existing `stack` binary](https://github.com/commercialhaskell/stack/releases)
and put it in `~/.local/bin`.

#### From source (using cabal-install):

    wget http://downloads.haskell.org/~ghc/7.10.3/ghc-7.10.3-armv7-deb8-linux.tar.xz && \
    tar xvf ghc-7.10.3-armv7-deb8-linux.tar.xz && \
    cd ghc-7.10.3 && \
    ./configure --prefix=/opt/ghc-7.10.3 && \
    sudo make install && \
    cd ..
    export PATH="/opt/ghc-7.10.3/bin:$PATH"
    wget https://www.haskell.org/cabal/release/cabal-install-1.24.0.0/cabal-install-1.24.0.0.tar.gz &&&&& \
    tar xvf cabal-install-1.24.0.0.tar.gz && \
    cd cabal-install-1.24.0.0 && \
    EXTRA_CONFIGURE_OPTS="" ./bootstrap.sh && \
    cd .. && \
    export PATH="$HOME/.cabal/bin:$PATH" && \
    cabal update

Edit `~/.cabal/config`, and set `executable-stripping: False` and
`library-stripping: False`.

    cabal unpack stack && \
    cd stack-* && \
    cabal install && \
    mv ~/.cabal/bin/stack ~/.local/bin

### Import GPG private key

Import the `dev@fpcomplete.com` (0x575159689BEFB442) GPG secret key

### Resources

  - http://mashu.github.io/2015/08/12/QEMU-Debian-armhf.html
  - https://www.aurel32.net/info/debian_arm_qemu.php
  - http://linuxdeveloper.blogspot.ca/2011/08/how-to-install-arm-debian-on-ubuntu.html
  - http://www.macworld.com/article/2855038/how-to-mount-and-manage-non-native-file-systems-in-os-x-with-fuse.html
  - https://github.com/alperakcan/fuse-ext2#mac-os
  - https://github.com/alperakcan/fuse-ext2/issues/31#issuecomment-214713801
  - https://github.com/alperakcan/fuse-ext2/issues/33#issuecomment-216758378
  - https://github.com/alperakcan/fuse-ext2/issues/32#issuecomment-216758019
  - http://osxdaily.com/2007/03/23/create-a-ram-disk-in-mac-os-x/

## Adding a new GHC version

  * Push new tag to our fork:

        git clone git@github.com:commercialhaskell/ghc.git
        cd ghc
        git remote add upstream git@github.com:ghc/ghc.git
        git fetch upstream
        git push origin ghc-X.Y.Z-release

  * [Publish a new Github release](https://github.com/commercialhaskell/ghc/releases/new)
    with tag `ghc-X.Y.Z-release` and same name.

  * Down all the relevant GHC bindists from https://www.haskell.org/ghc/download_ghc_X_Y_Z and upload them to the just-created Github release (see
    [stack-setup-2.yaml](https://github.com/fpco/stackage-content/blob/master/stack/stack-setup-2.yaml)
    for the ones we used in the last GHC release).

    In the case of macOS, repackage the `.xz` bindist as a `.bz2`, since macOS does
    not include `xz` by default or provide an easy way to install it.

    The script at `etc/scripts/mirror-ghc-bindists-to-github.sh` will help with
    this. See the comments within the script.

  * Build any additional required bindists (see below for instructions)

      * @@@ 32-bit/64-bit gmp4/centos67?
      * tinfo6 and tinfo6-nopie(`etc/vagrant/fedora-24-x86_64`)
      * ncurses6-nopie (`etc/vagrant/arch-x86_64`) -- be sure to upgrade VM, last time it wasn't nopie.  see if we can ask @cocreature to build, he did the last one (https://github.com/fpco/stackage-content/pull/26)
  * [Edit stack-setup-2.yaml](https://github.com/fpco/stackage-content/edit/master/stack/stack-setup-2.yaml)
    and add the new bindists, pointing to the Github release version. Be sure to
    update the `content-length` and `sha1` values.

### Building GHC

On systems with a small `/tmp`, you should set TMP and TEMP to an alternate
location.

For GHC >= 7.10.2, set the `GHC_VERSION` environment variable to the version to build:

  * `export GHC_VERSION=8.2.1`
  * `export GHC_VERSION=8.0.2`
  * `export GHC_VERSION=8.0.1`
  * `export GHC_VERSION=7.10.3a`
  * `export GHC_VERSION=7.10.2`

then, run (from [here](https://ghc.haskell.org/trac/ghc/wiki/Newcomers)):

    git config --global url."git://github.com/ghc/packages-".insteadOf git://github.com/ghc/packages/ && \
    git clone -b ghc-${GHC_VERSION}-release --recursive git://github.com/ghc/ghc ghc-${GHC_VERSION} && \
    cd ghc-${GHC_VERSION}/ && \
    cp mk/build.mk.sample mk/build.mk && \
    sed -i 's/^#BuildFlavour *= *perf$/BuildFlavour = perf/' mk/build.mk && \
    ./boot && \
    ./configure --enable-tarballs-autodownload && \
    sed -i 's/^TAR_COMP *= *bzip2$/TAR_COMP = xz/' mk/config.mk && \
    make -j$(cat /proc/cpuinfo|grep processor|wc -l) && \
    make binary-dist

GHC 7.8.4 is slightly different:

    export GHC_VERSION=7.8.4 && \
    git config --global url."git://github.com/ghc/packages-".insteadOf git://github.com/ghc/packages/ && \
    git clone -b ghc-${GHC_VERSION}-release --recursive git://github.com/ghc/ghc ghc-${GHC_VERSION} && \
    cd ghc-${GHC_VERSION}/ && \
    ./sync-all --extra --nofib -r git://git.haskell.org get -b ghc-7.8 && \
    cp mk/build.mk.sample mk/build.mk && \
    sed -i 's/^#BuildFlavour *= *perf$/BuildFlavour = perf/' mk/build.mk && \
    perl boot && \
    ./configure && \
    sed -i 's/^TAR_COMP *= *bzip2$/TAR_COMP = xz/' mk/config.mk && \
    make -j$(cat /proc/cpuinfo|grep processor|wc -l) && \
    make binary-dist
