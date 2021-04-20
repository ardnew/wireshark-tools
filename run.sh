#!/bin/bash
# ==============================================================================
#  run.sh configures the local environment to run one of the Wireshark tools.
# ------------------------------------------------------------------------------
#
#  This script must be installed in the Wireshark build subdirectory "run", 
#  where all of the tools are placed when building the project from source.
#
#  This subdirectory may then be copied elsewhere, anywhere, on the system:
#
#      # install the build subdirectory "run" to system library
#      cp -r /usr/local/src/wireshark/build/run /usr/local/lib/wireshark
#
#  Then, to run one of the tools, create a symlink with the same name as that
#  tool, pointing to this script, and place that symlink in your $PATH.
#
#  For example, to use this script for running "wireshark" and "tshark", which
#  were installed in the build subdirectory above:
#
#      # create "tshark" symlink in a globally-accessible $PATH directory
#      ln -s /usr/local/lib/wireshark/run.sh /usr/local/bin/tshark
#
#      # create "wireshark" symlink in a user's private $PATH directory
#      ln -s /usr/local/lib/wireshark/run.sh ~/.local/bin/wireshark
#
#  To install symlinks for ALL tools using these same paths:
#
#      # find all executables, placing symlinks to "run.sh" in global $PATH
#      find /usr/local/lib/wireshark -type f -executable \
#        \! \( -name "*.so*" -or -name run.sh \) -print0 | 
#          xargs -0 -L 1 basename | xargs -L 1 -I{} \
#            ln -s /usr/local/lib/wireshark/run.sh ~/.local/bin/wireshark/{}
#
# ------------------------------------------------------------------------------

# Kernel modules required for all Wireshark tools.
need_modules=( usbmon )

# Command used to load one kernel module.
load-module() { sudo modprobe "${1}" }

# Command used to unload one kernel module.
unload-module() { sudo modprobe -r "${1}" }

# ------------------------------------------------------------------------------

# All possible error conditions have a dedicated function with unique exit code
# and error message

exit-tool-not-found() {
	local name=${1} 
	local path=${2}
	erro "error: tool not found: ${name} (${path})"
	exit 1
}

exit-ambiguous-tool() {
	local name=${1} 
	local path=${@:2}
	erro "error: duplicate tool with name: ${name}"
	for p in "${path[@]}"; do
		erro "  -> ${p}"
	done
	exit 2
}

exit-missing-module() {
	local name=${1}
	erro "error: failed to load module: ${name}"
	exit 3
}

# ------------------------------------------------------------------------------

module-loaded() { lsmod | command grep -P "^${1}\b" &> /dev/null; }

# Load all given kernel modules which are not already loaded.
load-modules() {
	# First argument is an array reference which holds all modules loaded.
	# The caller can then use its elements as a list of modules to unload.
	local -n result=${1}; shift
	for mod in "${@}"; do
		# Check if module already loaded.
		if ! module-loaded "${mod}"; then
			# Add module to list of self-loaded modules.
			result+=( "${mod}" )
			# Load module or bail out.
			load-module "${mod}" ||
				exit-missing-module "${mod}"
			erro "${tool_name}: loaded module: ${mod}"
		fi
	done
}

# Unload all given kernel modules.
unload-modules() {
	for mod in "${@}"; do
		# Verify module currently loaded.
		if module-loaded "${mod}"; then
			# Unload module or print warning.
			unload-module "${mod}" ||
				erro "warning: failed to unload module: ${mod}"
		fi
	done
}

# Run a given Wireshark tool with modified environment.
run() {
	local bin=${1}
	local lib=${2} 
	local -a loaded
	# Determine which required modules are not loaded and load them.
	load-modules loaded "${need_modules[@]}"
	# Execute with modified environment and given args.
	LD_LIBRARY_PATH="${lib}" "${bin}" "${@:2}"
	# Unload all required modules which were not previously loaded.
	unload-modules "${loaded[@]}"
}

# Just use echo if github.com/ardnew/erro not installed.
type -P erro &> /dev/null || alias erro=echo

# Get physical path to this script (directory where all tools were built)
wireshark_path=$( readlink -f "${0}" )
wireshark_path=$( dirname "${wireshark_path}" )

# Get the name of the tool we are wanting to run (the symlink filename).
tool_name=$( basename "${0}" )

# Locate the tool with the same name somewhere below our Wireshark installation
# path (where run.sh is located); the file must have execute permissions.
tool_path=( "$( 
	find "${wireshark_path}" -type f -executable -name "${tool_name}" -print0 |
		xargs -0 -L 1
)" )

# Verify the number of files found is exactly one; and then run it.
case ${#tool_path[@]} in
	# Unique tool found, configure environment and run tool.
	1) run "${tool_path[0]}" "${wireshark_path}" "${@}" ;;
	# No tool found matching name of symlink.
	0) exit-tool-not-found "${tool_name}" "${wireshark_path}" ;;
	# More than one tool found matching name of symlink.
	*) exit-ambiguous-tool "${tool_name}" "${tool_path[@]}" ;;
esac

