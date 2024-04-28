# wait-for

`wait-for-it.sh` is a pure bash/dash script that will wait
  until response from a host and TCP port, then execute a command.

Useful when waitig for a service to start up in a containerized environment,
 or during deployments, ensuring that dependency services are available
 before proceeding.

Supports customizable timeouts, silent operation, and strict mode checks,
 allowing for versatile and robust startup or deployment scripts.

The script is now usable both with Bash and Dash
 (a fork of Kenneth Almquist's ash shell integrated to BusyBox).

 https://en.wikipedia.org/wiki/Almquist_shell

Dash / BusyBox is used in distributions like Alpine Linux, DSLinux,
 and Linux-based router firmware such as OpenWrt, Tomato and DD-WRT.
Alpine Linux is popular for building small container images for Docker or K8s.


## Requirements

Since it is a pure bash/dash script, it does not have any
 external dependencies on systems with BusyBox, like Alpine Linux,
 as all commands are provided by BusyBox (through symlinks).

On systems with bash, these external commands are used:
 basename, date, echo, nc (netcat/ncat), sleep


## Usage

```text
 WAIT-FOR.SH bash/dash script by Péter Vámos https://github.com/pvamos/wait-for

   Wait until response from a host and TCP port.

 Usage:
  wait-for.sh host:port [-s] [-t timeout] [-q] [-- command args]
    or
  wait-for.sh -h host -p port [-s] [-t timeout] [-q] [-- command args]

  -h HOST | -h=HOST | --host=HOST | --host HOST   Host or IP under test
  -p PORT | -p=PORT | --port=PORT | --port PORT   TCP port under test
                          Alternatively, specify the host and port as host:port

  -s | --strict               Only execute subcommand if the test succeeds
  -q | --quiet                Don't output any status messages

  -t TIMEOUT | -t=TIMEOUT | --timeout=TIMEOUT | --timeout TIMEOUT
                              Timeout in seconds, zero for no timeout

  -- COMMAND ARGS             Execute command with args after the test finishes
```


## Credits and references

Copyright (c) 2024 Péter Vámos

  https://github.com/pvamos
  pvamos@gmail.com
  https://linkedin.com/in/pvamos

This software is based on "wait-for-it" originally created by Giles Hall
 (copyright (c) 2016, last updated in 2020),
 published and available at: https://github.com/vishnubob/wait-for-it

This version includes modifications made by Péter Vámos in 2024,
 published and available at: https://github.com/pvamos/wait-for

Both the original and modified software are distributed under
 the MIT License, which is included below.


## What has been refactored

Focused on making it more reliable, user-friendly, and versatile across
 different Unix-like environments.
 
The improvements specifically targeted error handling, precise timeout control,
 efficient network checks, detailed user guidance, and strict adherence
 to POSIX standards for broader shell compatibility.
These make the script suitable for critical automation tasks
 in modern, containerized infrastructures.

### Timeout Implementation

Implemented a precise timeout mechanism using actual elapsed time calculated
 with `date +%s`. This method ensures that the script adheres strictly to the
 user-specified timeout regardless of network delays or system load, which
 could affect loop iteration speed.

### Argument Parsing and Usage Information

The argument parsing was enhanced to handle both shorthand and long-form
 arguments robustly, supporting a broader range of input formats.
Expanded the usage function to give detailed descriptions of all available
 options, improving user guidance.

### Robustness and Compatibility

Rewritten for full POSIX compliance, ensuring that the script can run not only
 in Bash but also in more restricted shells like the Dash / BusyBox fork of
 Kenneth Almquist's ash shell, which is common in lightweight environments
 like Docker containers based on Alpine Linux.


## Examples

For example, let's test to see if we can access port 80 on `www.google.com`,
and if it is available, echo the message `google is up`.

```text
$ ./wait-for.sh www.google.com:80 -- echo "google is up"
2024-04-28T11:28:32,315Z wait-for.sh www.google.com:80 - Timeout parameter not specified, defauting to 15 seconds.
2024-04-28T11:28:32,352Z wait-for.sh www.google.com:80 - Response after 0 seconds, executing command: 'echo google is up'
google is up
```

You can set your own timeout with the `-t` or `--timeout=` option.  Setting
the timeout value to 0 will disable the timeout:

```text
$ ./wait-for.sh -t 0 www.google.com:80 -- echo "google is up"
2024-04-28T11:28:55,048Z wait-for.sh www.google.com:80 - Timeout parameter value is 0, waiting indefinitely.
2024-04-28T11:28:55,079Z wait-for.sh www.google.com:80 - Response after 0 seconds, executing command: 'echo google is up'
google is up
```

The subcommand will be executed regardless if the service is up or not.  If you
wish to execute the subcommand only if the service is up, add the `--strict` or `-s`
argument. In this example, we will test port 81 on `www.google.com` which will
fail:

```text
./wait-for.sh www.google.com:81 --timeout=3 --strict -- echo "google is up"
2024-04-28T11:29:27,304Z wait-for.sh www.google.com:81 - Waiting for 3 seconds.
2024-04-28T11:29:30,335Z wait-for.sh www.google.com:81 - No response in 3 seconds, strict mode, refusing to execute command: 'echo google is up'
```

If you don't want to execute a subcommand, leave off the `--` argument.  This
way, you can test the exit condition of `wait-for-it.sh` in your own scripts,
and determine how to proceed:

```text
$ ./wait-for.sh www.google.com:80
2024-04-28T11:30:39,702Z wait-for.sh www.google.com:80 - Timeout parameter not specified, defauting to 15 seconds.
2024-04-28T11:30:39,736Z wait-for.sh www.google.com:80 - Response after 0 seconds and no command specified.
$ echo $?
0
$ ./wait-for.sh www.google.com:81
2024-04-28T11:31:45,954Z wait-for.sh www.google.com:81 - Timeout parameter not specified, defauting to 15 seconds.
2024-04-28T11:32:01,134Z wait-for.sh www.google.com:81 - No response in 15 seconds and no command specified.
$ echo $?
1
```

The silent mode (`--quiet` or `-q`) disables all output from the script:

```text
$ ./wait-for.sh -s -t 5 -q www.google.com:81 -- echo "google is up"
$ ./wait-for.sh -s -t 5 -q www.google.com:80 -- echo "google is up"
google is up
```

## License

MIT License

Copyright (c) 2024 Péter Vámos  pvamos@gmail.com  https://github.com/pvamos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.