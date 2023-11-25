# mmsh

An experimental CLI parser.

## What's inside?

A command prompt built on top of [GNU Readline][readline], and a command parser
that outputs a data structure that can be used to run the commands entered.

### A simple example

If you were to type the following into `mmsh`:

```bash
$ foo < bar | baz > fizz.txt
```

... it would be interpreted in the following way:

* Run command `foo`, getting its input from `bar`
* Run command `baz`, whose input came from the output of `foo`
* Write the output of `baz` to `fizz.txt`

### an IRB session

```irb
 > Mmsh.parse(Mmsh.read('>'))
 > foo < bar.input | baz > fizz.output
=>
[#<struct Mmsh::Cmd
  id="d2e22c61-8b93-4e24-bd7a-079b50430060",
  name="foo",
  args="",
  input="bar.input",
  output="d2e22c61-8b93-4e24-bd7a-079b50430060">,
 #<struct Mmsh::Cmd
  id="4140c384-eac8-4fad-9c4f-0bb8b1862a9d",
  name="|",
  args="",
  input=nil,
  output="4140c384-eac8-4fad-9c4f-0bb8b1862a9d">,
 #<struct Mmsh::Cmd
  id="5fe10da0-1b9a-4619-adcb-a231602daa27",
  name="baz",
  args="",
  input="d2e22c61-8b93-4e24-bd7a-079b50430060",
  output="fizz.output">]
```

## Why build this?

I've been working on a few fun side projects lately built around a basic shell,
but not requiring a full OS under it. `mmsh` is my attempt at building just the
CLI part.

The execution of the commands parsed is inteded to be run by something else --
anything else that can interpret the data structure that `mmsh` creates.

## The parts

The code in `mmsh` is made up of relatively few parts:

### Command execution

- A `Reader` that reads your commands from the command line
- A `Parser` that parses the command(s) you type in, into a simple data
  structure that can the be executed (or run)

  [readline]: https://tiswww.case.edu/php/chet/readline/rltop.html
