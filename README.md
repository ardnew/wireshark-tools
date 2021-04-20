# wireshark-tools
### Wireshark [scripts](README.md#scripts), [rules](README.md#rules), and [filters](README.md#filters)

## Scripts

 - [`run.sh`](run.sh) — **Configure local environment temporarily and run a Wireshark tool.**

This script must be installed in the Wireshark build subdirectory `run`, where all of the tools are placed when building the project from source.

This subdirectory may then be copied elsewhere, anywhere, on the system:

```sh
# install the build subdirectory "run" to system library
cp -r /usr/local/src/wireshark/build/run /usr/local/lib/wireshark
```

Then, to run one of the tools, create a symlink with the same name as that tool, pointing to this script, and place that symlink in your `$PATH`.

For example, to use this script for running `wireshark` and `tshark`, which were installed in the build subdirectory above:

```sh
# create "tshark" symlink in a globally-accessible $PATH directory
ln -s /usr/local/lib/wireshark/run.sh /usr/local/bin/tshark

# create "wireshark" symlink in a user's private $PATH directory
ln -s /usr/local/lib/wireshark/run.sh ~/.local/bin/wireshark
```

To install symlinks for ALL tools using these same paths:

```sh
# find all executables, placing symlinks to "run.sh" in global $PATH
find /usr/local/lib/wireshark -type f -executable \
    \! \( -name "*.so*" -or -name run.sh \) -print0 |
        xargs -0 -L 1 basename | xargs -L 1 -I{} \
            ln -s /usr/local/lib/wireshark/run.sh ~/.local/bin/wireshark/{}
```

## Rules

 - [`colorfilters/usb-device.rules`](colorfilters/usb-device.rules) — Colorization rules for USB 2.0 device setup/configuration packets
