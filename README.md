# wait-for-it

`wait-for-it.sh` is a pure bash script that will wait on the availability of a
 host and TCP port. It is useful when it is necessary to wait for a service
 to start upin a containerized environment or during deployments,
 ensuring that dependent services are available before proceeding.

Since it is a pure bash script, it does not have any external dependencies.

Supports customizable timeouts, silent operation, and strict mode checks,
 allowing for versatile and robust startup or deployment scripts.

The script is now usable both with Bash and Dash
 (a fork of Kenneth Almquist's ash shell integrated to BusyBox).
 https://en.wikipedia.org/wiki/Almquist_shell
Dash / BusyBox is used in distributions like Alpine Linux, DSLinux,
 and Linux-based router firmware such as OpenWrt, Tomato and DD-WRT.
Alpine Linux is popular for building small container images for Docker or K8s.


## Credits and references

Based on the 2016 work of Giles Hall (last updated in 2020),
 published at https://github.com/vishnubob/wait-for-it under MIT license.

 Created by Péter Vámos in 2024
  https://github.com/pvamos
  pvamos@gmail.com
  https://linkedin.com/in/pvamos/


## What has been refactored

The transformation from the initial to the final version of the script focused on making it more reliable, user-friendly, and versatile across different Unix-like environments. The improvements specifically targeted error handling, precise timeout control, efficient network checks, detailed user guidance, and strict adherence to POSIX standards for broader shell compatibility. These enhancements make the script suitable for more complex and critical automation tasks in modern, containerized infrastructures.

### Timeout Implementation

    Implemented a precise timeout mechanism using actual elapsed time calculated with `date +%s`. This method ensures that the script adheres strictly to the user-specified timeout regardless of network delays or system load, which could affect loop iteration speed.

### Argument Parsing and Usage Information

    The argument parsing was enhanced to handle both shorthand and long-form arguments robustly, supporting a broader range of input formats. Expanded the usage function to give detailed descriptions of all available options, improving user guidance.

### Robustness and Compatibility

    Rewritten for full POSIX compliance, ensuring that the script can run not only in Bash but also in more restricted shells like Dash / BusyBox fork of Kenneth Almquist's ash shell, which is common in lightweight environments like Docker containers based on Alpine Linux.


## Usage

```text
Usage:
  wait-for-it.sh host:port [-s] [-t timeout] [-- command args]
    or
  wait-for-it.sh -h host -p port [-s] [-t timeout] [-- command args]

  -h HOST | -h=HOST | --host=HOST | --host HOST   Host or IP under test
  -p PORT | -p=PORT | --port=PORT | --port PORT   TCP port under test
                          Alternatively, specify the host and port as host:port

  -s | --strict               Only execute subcommand if the test succeeds
  -q | --quiet                Don't output any status messages

  -t TIMEOUT | -t=TIMEOUT | --timeout=TIMEOUT | --timeout TIMEOUT
                              Timeout in seconds, zero for no timeout

  -- COMMAND ARGS             Execute command with args after the test finishes
```


## Examples

For example, let's test to see if we can access port 80 on `www.google.com`,
and if it is available, echo the message `google is up`.

```text
$ ./wait-for-it.sh www.google.com:80 -- echo "google is up"
wait-for-it.sh: waiting 15 seconds for www.google.com:80
wait-for-it.sh: www.google.com:80 is available after 0 seconds
google is up
```

You can set your own timeout with the `-t` or `--timeout=` option.  Setting
the timeout value to 0 will disable the timeout:

```text
$ ./wait-for-it.sh -t 0 www.google.com:80 -- echo "google is up"
wait-for-it.sh: waiting for www.google.com:80 without a timeout
wait-for-it.sh: www.google.com:80 is available after 0 seconds
google is up
```

The subcommand will be executed regardless if the service is up or not.  If you
wish to execute the subcommand only if the service is up, add the `--strict`
argument. In this example, we will test port 81 on `www.google.com` which will
fail:

```text
$ ./wait-for-it.sh www.google.com:81 --timeout=1 --strict -- echo "google is up"
wait-for-it.sh: waiting 1 seconds for www.google.com:81
wait-for-it.sh: timeout occurred after waiting 1 seconds for www.google.com:81
wait-for-it.sh: strict mode, refusing to execute subprocess
```

If you don't want to execute a subcommand, leave off the `--` argument.  This
way, you can test the exit condition of `wait-for-it.sh` in your own scripts,
and determine how to proceed:

```text
$ ./wait-for-it.sh www.google.com:80
wait-for-it.sh: waiting 15 seconds for www.google.com:80
wait-for-it.sh: www.google.com:80 is available after 0 seconds
$ echo $?
0
$ ./wait-for-it.sh www.google.com:81
wait-for-it.sh: waiting 15 seconds for www.google.com:81
wait-for-it.sh: timeout occurred after waiting 15 seconds for www.google.com:81
$ echo $?
124
```


## License

MIT License

Copyright (c) 2024 Péter Vámos

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