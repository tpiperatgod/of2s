# OpenFunction demo tool

Welcome to the OpenFunction QuickStart Tool!

It will build an OpenFunction demo environment by following steps:

1. Create a cluster named 'openfunction' by Kind

2. Install OpenFunction's dependencies

3. Prepare Knative gateway (use Kind ip as External address)

4. Install OpenFunction

5. Create a sample function

> Note: It will output the log to the `openfunction.log` file under the current path, and you can watch the log by execute `tail -f openfunction.log`.

## Prerequisites

- kubectl(>=v1.20.0) in your `PATH`

- kind(>=v0.11.0) in your `PATH`

- go(>=1.15) in your `PATH`

* docker(>=19.3.8) in your `PATH`

