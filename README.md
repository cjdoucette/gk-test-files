# gk-test-files
Files for stress testing the GK block

## Dependencies

To generate statistics, you will need `python3` and `numpy`:

    # apt install python3
    # apt install pip3
    $ pip3 install numpy

## How to use

There are two main scripts: `run_test.sh` and `run_many.sh`.

### `run_test.sh`

`run_test.sh` is meant to run a single experiment. It starts Gatekeeper
(using whatever configuration is currently set up), adds a FIB entry,
and starts the bots. It terminates after a configurable amount of time.

The parameters to the script are:

    ./run_test.sh experiment_name table_exponent num_lcores num_bots experiment_length trial_num

Where:

* `experiment_name` is a name for the experiment
* `table_exponent` is an exponent n for the size (2^n) of each GK blocks' flow table
* `num_lcores` is the number of lcores to run, i.e. the number of GK instances
* `num_bots` is the number of bots to run
* `experiment_length` is the length of the experiment in seconds
* `trial_num` is the trial number

For example, you might run it with:

    ./run_test.sh patch1 10 1 8 300 1

The script will produce log files in the gatekeeper directory using
the experiment name as a directory name. It will name the logs using
the parameters of the experiment.

### `run_many.sh`

`run_many.sh` is meant to run multiple experiments while changing the
configuration parameters. By default, it is set up to run over multiple
numbers of lcores and multiple table sizes, but these for loops can be
changed to run any different parameters for `run_test.sh`.

The script changes the gatekeeper configuration files as needed and
repeatedly runs experiments. By default, it changes the `n_lcores`
variable and the `flow_ht_size` variable (and has nested for loops to
iterate over values for these variables), but it could be changed to
fit whatever variable you are changing for your experiments. If you do
change them, you will likely want to pass those variable values to
`run_test.sh` as well.

The script also collects client and Gatekeeper statistics and outputs them
to a file in the form of a Markdown table. The name of the output file
is {experiment_name}.log.

The script has only one parameter: the experiment name. For example:

    ./run_many.sh test

### `sendRawEth{Random}.c`

These are C programs that send Ethernet packets as quick as possible
to represent flooding bots. Note that they currently don't have correct
IP or UDP headers.

The `sendRawEthRandom.c` program uses a random source address, triggering
flow table churn in the GK blocks. This is used by default in the other
testing scripts.

The `sendRawEth.c` program is capable of sending packets using only
a few flows (so as to not overflow the GK flow tables). To make sure
each lcore actually receives packets, the source addresses have to
be crafted in a way that makes sure they are distributed. To do so,
Gatekeeper should be run with the source address --> lcore mapping
showing, so that `sendRawEth.c` can be edited with those source
addresses. This file is currently not in use in the scripts.

### `process_gk_stats.py`

A Python script that computes and outputs averages of the Gatekeeper
performance according to the log files. Currently called by
the `run_many.sh` script.
