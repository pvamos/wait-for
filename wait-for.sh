#!/bin/sh


# This is a pure bash/ash script that will wait
#  until response from a host and TCP port, then execute a command.
#
# Useful when waitig for a service to start up in a containerized environment,
#  or during deployments, ensuring that dependency services are available
#  before proceeding.
#
# Supports customizable timeouts, silent operation, and strict-mode checks,
#  allowing for versatile and robust startup or deployment scripts.


#  WAIT-FOR.SH bash/ash script by Péter Vámos https://github.com/pvamos/wait-for
#
#    Wait until response from a host and TCP port, then execute a command.
#
#  Usage:
#   wait-for.sh host:port [-s] [-t timeout] [-q] [-- command args]
#     or
#   wait-for.sh -h host -p port [-s] [-t timeout] [-q] [-- command args]
#
#   -h HOST | -h=HOST | --host=HOST | --host HOST   Host or IP under test
#   -p PORT | -p=PORT | --port=PORT | --port PORT   TCP port under test
#                           Alternatively, specify the host and port as host:port
# 
#   -s | --strict               Only execute subcommand if the test succeeds
#   -q | --quiet                Don't output any status messages
#
#   -t TIMEOUT | -t=TIMEOUT | --timeout=TIMEOUT | --timeout TIMEOUT
#                               Timeout in seconds, zero for no timeout
#
#   -- COMMAND ARGS             Execute command with args after the test finishes


# Since it is a pure bash/ash script, it does not have any
#  external dependencies on systems with BusyBox, like Alpine Linux,
#  as all commands are provided by BusyBox (through symlinks).
# On systems with bash, these external commands are used:
#  `basename`, `date`, `echo`, `expr`, `nc` (netcat/ncat), `sleep`.
#
# The script is usable both with Bash and Ash
#  (a fork of Kenneth Almquist's ash shell integrated to BusyBox).
#  https://en.wikipedia.org/wiki/Almquist_shell
# Ash / BusyBox is used in distributions like Alpine Linux, DSLinux,
#  and Linux-based router firmware such as OpenWrt, Tomato and DD-WRT.
# Alpine Linux is popular for building small container images for Docker or K8s.


# Copyright notice:
#
# Copyright (c) 2024 Péter Vámos
#
#   https://github.com/pvamos
#   pvamos@gmail.com
#   https://linkedin.com/in/pvamos
#
# This software is based on "wait-for-it" originally created by Giles Hall
#  (copyright (c) 2016, last updated in 2020),
#  published and available at: https://github.com/vishnubob/wait-for-it
#
# This version includes modifications made by Péter Vámos in 2024,
#  published and available at: https://github.com/pvamos/wait-for
# Both the original and modified software are distributed under
#  the MIT License, which is included below.
#
#
# MIT License
#
# Copyright (c) 2024 Péter Vámos  pvamos@gmail.com  https://github.com/pvamos
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


# Get the base name of the script itself.
WAITFOR_cmdname=$(basename "$0")

# Print error messages to stderr with ISO-8601 UTC time with milliseconds, if not in quiet mode.
echoerr() {
    if [ "$WAITFOR_QUIET" -ne 1 ]; then
        # This is '2024-05-01T18:26:22,598Z' with coreutils, and '2024-05-01T18:26:22,' with BusyBox
        current_datetime=$(date -u +'%Y-%m-%dT%H:%M:%S,%3NZ')

        # Check coreutils or BusyBox (i.e., ends with ','?)
        if [ "${current_datetime: -1}" = "," ]; then
            # get milliseconds with adjtimex
            milliseconds=$(adjtimex | awk '/time.tv_usec/ {print substr($2, 1, 3)}')
            # Append
            current_datetime="${current_datetime}${milliseconds}Z"
        fi

        # Print date and message to stderr
        echo "$current_datetime $@" 1>&2
    fi
}

# Print usage information and exit the script.
usage()
{
    cat << USAGE >&2

 WAIT-FOR.SH bash/ash script by Péter Vámos https://github.com/pvamos/wait-for

   Wait until response from a host and TCP port, then execute a command.

 Usage:
  $WAITFOR_cmdname host:port [-s] [-t timeout] [-q] [-- command args]
    or
  $WAITFOR_cmdname -h host -p port [-s] [-t timeout] [-q] [-- command args]

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

# Wait for the specified host and port to become available or until the timeout is reached.
# If timeout parameter -t or --timeout value is 0, then listen indefinitely.
wait_for()
{
  # Loop until the timeout is reached.
    while true; do
        # Calculate elapsed time.
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        # Check for timeout if timeout parameter is not 0.
        if [ "$WAITFOR_TIMEOUT" -ne 0 ]; then
            # Check if the timeout has been reached.
            if [ "$elapsed_time" -ge "$WAITFOR_TIMEOUT" ]; then
                # No response within timeout.
                return 1
            fi
        fi

        # Try to connect to the specified port with a timeout of 1 second.
        if nc -w 1 -z "$WAITFOR_HOST" "$WAITFOR_PORT" >/dev/null 2>&1; then
            # nc got a response
            return 0
        fi
        # Wait for 1 second before trying again.
        sleep 1
    done
}

# Record the start time.
start_time=$(date +%s)

# Initialize default flags.
WAITFOR_QUIET=0
WAITFOR_STRICT=0
WAITFOR_DEFAULT=15

# Parse command-line arguments.
while [ $# -gt 0 ]; do
    case "$1" in
        *:* )
        # Split host and port using ':' as the delimiter.
        WAITFOR_HOST="${1%:*}"
        WAITFOR_PORT="${1##*:}"
        shift
        ;;
        -q | --quiet)
        WAITFOR_QUIET=1
        shift
        ;;
        -s | --strict)
        WAITFOR_STRICT=1
        shift
        ;;
        -h | --host)
        WAITFOR_HOST="$2"
        shift 2
        ;;
        -h=* | --host=*)
        WAITFOR_HOST="${1#*=}"
        shift
        ;;
        -p | --port)
        WAITFOR_PORT="$2"
        shift 2
        ;;
        -p=* | --port=*)
        WAITFOR_PORT="${1#*=}"
        shift
        ;;
        -t | --timeout)
        # force WAITFOR_TIMEOUT to be integer
        WAITFOR_TIMEOUT=$(expr "$2" + 0)
        shift 2
        ;;
        -t=* | --timeout=*)
        # force WAITFOR_TIMEOUT to be integer
        WAITFOR_TIMEOUT=$(expr "${1#*=}" + 0)
        shift
        ;;
        --)
        # End of options, subsequent arguments are part of the command to execute.
        shift
        WAITFOR_CLI="$@"
        break
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "$WAITFOR_cmdname - Unknown argument: $1"
        usage
        ;;
    esac
done

# Check for mandatory parameters.
if [ -z "$WAITFOR_HOST" ] || [ -z "$WAITFOR_PORT" ]; then
    echoerr "$WAITFOR_cmdname - Error: you need to provide a host and port to test."
    usage
fi

# Set a default timeout if not specified (keep 0 if set).
  if [ -z "$WAITFOR_TIMEOUT" ]; then
      WAITFOR_TIMEOUT="$WAITFOR_DEFAULT"
      echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - Timeout parameter not specified, defauting to $WAITFOR_TIMEOUT seconds."
  else
      # Default timeout specified, check if timeout parameter is not 0.
      if [ "$WAITFOR_TIMEOUT" -ne 0 ]; then
          echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - Waiting for $WAITFOR_TIMEOUT seconds."
      else
          echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - Timeout parameter value is 0, waiting indefinitely."
      fi
  fi

# Call the wait function and capture the result.
wait_for
WAITFOR_RESULT=$?

# Decide what to do based on parameters and the result of the wait function.
if [ -n "$WAITFOR_CLI" ] && [ "$WAITFOR_RESULT" -eq 0 ]; then
    echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - Response after $elapsed_time seconds, executing command: '$WAITFOR_CLI'"
    exec $WAITFOR_CLI
elif [ -n "$WAITFOR_CLI" ] && [ "$WAITFOR_RESULT" -eq 1 ] && [ "$WAITFOR_STRICT" -eq 0 ]; then
    echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - No response in $WAITFOR_TIMEOUT seconds, non-strict mode, executing command: '$WAITFOR_CLI'"
    exec $WAITFOR_CLI
elif [ -n "$WAITFOR_CLI" ] && [ "$WAITFOR_RESULT" -eq 1 ] && [ "$WAITFOR_STRICT" -eq 1 ]; then
    echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - No response in $WAITFOR_TIMEOUT seconds, strict mode, refusing to execute command: '$WAITFOR_CLI'"
    exit $WAITFOR_RESULT
elif [ -z "$WAITFOR_CLI" ] && [ "$WAITFOR_RESULT" -eq 0 ]; then
    echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - Response after $elapsed_time seconds and no command specified."
elif [ -z "$WAITFOR_CLI" ] && [ "$WAITFOR_RESULT" -eq 1 ]; then
    echoerr "$WAITFOR_cmdname $WAITFOR_HOST:$WAITFOR_PORT - No response in $WAITFOR_TIMEOUT seconds and no command specified."
    exit $WAITFOR_RESULT
fi
