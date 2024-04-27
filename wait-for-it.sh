#!/bin/sh


# This is a pure bash/dash script that will wait
#  until the availability of a host and TCP port. 
#
# Useful when it is necessary to wait for a service to start up
#  in a containerized environment or during deployments,
#  ensuring that dependency services are available before proceeding.
#
# Supports customizable timeouts, silent operation, and strict mode checks,
#  allowing for versatile and robust startup or deployment scripts.


# Usage:
#   wait-for-it.sh host:port [-s] [-t timeout] [-- command args]
#     or
#   wait-for-it.sh -h host -p port [-s] [-t timeout] [-- command args]
#
#   -h HOST | -h=HOST | --host=HOST | --host HOST   Host or IP under test
#   -p PORT | -p=PORT | --port=PORT | --port PORT   TCP port under test
#                           Alternatively, specify the host and port as host:port
#
#   -s | --strict               Only execute subcommand if the test succeeds
#   -q | --quiet                Don't output any status messages

#   -t TIMEOUT | -t=TIMEOUT | --timeout=TIMEOUT | --timeout TIMEOUT
#                               Timeout in seconds, zero for no timeout
# 
#   -- COMMAND ARGS             Execute command with args after the test finishes


# Since it is a pure bash/dash script, it does not have any
#  external dependencies on systems with BusyBox, like Alpine Linux,
#  as all commands are provided by BusyBox (through symlinks).
# On systems with bash, these external commands are used:
#  basename, date, echo, nc (netcat/ncat), sleep
#
# The script is usable both with Bash and Dash
#  (a fork of Kenneth Almquist's ash shell integrated to BusyBox).
#  https://en.wikipedia.org/wiki/Almquist_shell
# Dash / BusyBox is used in distributions like Alpine Linux, DSLinux,
#  and Linux-based router firmware such as OpenWrt, Tomato and DD-WRT.
# Alpine Linux is popular for building small container images for Docker or K8s.


# Based on the 2016 work of Giles Hall (last updated in 2020),
#  published at https://github.com/vishnubob/wait-for-it under MIT license.

# Created by Péter Vámos in 2024
#   https://github.com/pvamos
#   pvamos@gmail.com
#   https://linkedin.com/in/pvamos


# MIT License
#
# Copyright (c) 2024 Péter Vámos
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Get the base name of the script itself
WAITFORIT_cmdname=$(basename "$0")

# Function to print error messages to stderr if not in quiet mode
echoerr() { if [ "$WAITFORIT_QUIET" -ne 1 ]; then echo "$@" 1>&2; fi }

# Function to print usage information and exit the script
usage()
{
    cat << USAGE >&2

Usage:
  $WAITFORIT_cmdname host:port [-s] [-t timeout] [-- command args]
    or
  $WAITFORIT_cmdname -h host -p port [-s] [-t timeout] [-- command args]

  -h HOST | -h=HOST | --host=HOST | --host HOST   Host or IP under test
  -p PORT | -p=PORT | --port=PORT | --port PORT   TCP port under test
                          Alternatively, specify the host and port as host:port

  -s | --strict               Only execute subcommand if the test succeeds
  -q | --quiet                Don't output any status messages

  -t TIMEOUT | -t=TIMEOUT | --timeout=TIMEOUT | --timeout TIMEOUT
                              Timeout in seconds, zero for no timeout

  -- COMMAND ARGS             Execute command with args after the test finishes

USAGE
    exit 1
}

# Function to wait for the specified host and port to become available or until the timeout is reached
wait_for()
{
    # Set a default timeout if not specified
    if [ -z "$WAITFORIT_TIMEOUT" ]; then
        WAITFORIT_TIMEOUT=15
    fi

    # Record the start time
    start_time=$(date +%s)
    echoerr "$WAITFORIT_cmdname: waiting $WAITFORIT_TIMEOUT seconds for $WAITFORIT_HOST:$WAITFORIT_PORT"

    # Loop until the timeout is reached
    while true; do
        # Calculate elapsed time
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        # Check if the timeout has been reached
        if [ "$elapsed_time" -ge "$WAITFORIT_TIMEOUT" ]; then
            echoerr "$WAITFORIT_cmdname: timeout occurred after waiting $WAITFORIT_TIMEOUT seconds for $WAITFORIT_HOST:$WAITFORIT_PORT"
            return 1
        fi

        # Try to connect to the specified port with a timeout of 1 second
        if nc -w 1 -z "$WAITFORIT_HOST" "$WAITFORIT_PORT" >/dev/null 2>&1; then
            echoerr "$WAITFORIT_cmdname: $WAITFORIT_HOST:$WAITFORIT_PORT is available after $elapsed_time seconds"
            return 0
        fi
        # Wait for 1 second before trying again
        sleep 1
    done
}

# Initialize default flags
WAITFORIT_QUIET=0
WAITFORIT_STRICT=0
WAITFORIT_TIMEOUT=15

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        *:* )
        # Split host and port using ':' as the delimiter
        WAITFORIT_HOST="${1%:*}"
        WAITFORIT_PORT="${1##*:}"
        shift
        ;;
        -q | --quiet)
        WAITFORIT_QUIET=1
        shift
        ;;
        -s | --strict)
        WAITFORIT_STRICT=1
        shift
        ;;
        -h | --host)
        WAITFORIT_HOST="$2"
        shift 2
        ;;
        -h=* | --host=*)
        WAITFORIT_HOST="${1#*=}"
        shift
        ;;
        -p | --port)
        WAITFORIT_PORT="$2"
        shift 2
        ;;
        -p=* | --port=*)
        WAITFORIT_PORT="${1#*=}"
        shift
        ;;
        -t | --timeout)
        WAITFORIT_TIMEOUT="$2"
        shift 2
        ;;
        -t=* | --timeout=*)
        WAITFORIT_TIMEOUT="${1#*=}"
        shift
        ;;
        --)
        # End of options, subsequent arguments are part of the command to execute
        shift
        WAITFORIT_CLI="$@"
        break
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

# Check for mandatory parameters
if [ -z "$WAITFORIT_HOST" ] || [ -z "$WAITFORIT_PORT" ]; then
    echoerr "Error: you need to provide a host and port to test."
    usage
fi

# Call the wait function and capture the result
wait_for
WAITFORIT_RESULT=$?

# Decide what to do based on the result of the wait function
if [ -n "$WAITFORIT_CLI" ] && ( [ "$WAITFORIT_RESULT" -eq 0 ] || [ "$WAITFORIT_STRICT" -eq 0 ] ); then
    exec $WAITFORIT_CLI  # Execute the command if check was successful or not in strict mode
elif [ -z "$WAITFORIT_CLI" ] && ( [ "$WAITFORIT_RESULT" -eq 0 ] || [ "$WAITFORIT_STRICT" -eq 0 ] ); then
    :  # Do nothing if no command is provided and exit cleanly
else
    echoerr "$WAITFORIT_cmdname: strict mode, refusing to execute subprocess"
    exit $WAITFORIT_RESULT
fi
