require 'readline'
require 'securerandom'

module MMSH
  Cmd = Struct.new(:id, :name, :args, :input, :output)

  def self.read(prompt)
    cmd_lines = []

    loop do
      cmd = Readline.readline("#{prompt} ", false).rstrip
      Readline::HISTORY.push(cmd) unless cmd.empty?
      cmd_lines << minimize(cmd)

      if cmd.end_with?('\\')
        next
      else
        break
      end
    end

    cmd_lines.join
  end

  # Takes a command string that may contain leading and/or trailing whitespace,
  # as well as the line continuation character ('\'), and produces a single
  # string with all of that stripped out. Multiple lines get combined, with
  # continuation removed.
  #
  # This:
  #   >   foo \
  #   > bar
  #
  # Becomes:
  #   'foo bar'
  #
  # This:
  #   >   foo\
  #   >bar
  #
  # Becomes:
  #   'foobar'
  def self.minimize(cmd)
    min_strip(
      strip_continuation(cmd)
    )
  end

  # Takes a command that may or may not contain line continuation, and removes
  # it if it's present.
  def self.strip_continuation(cmd)
    cmd.rstrip.end_with?('\\') ? cmd.rstrip[0..-2] : cmd.rstrip
  end

  def self.min_strip(cmd)
    rpad = cmd.end_with?(' ') ? ' ' : ''

    "#{cmd.strip}#{rpad}"
  end

  ## Parsing methods

  ##
  # Takes a string captured from a CLI containing one or more commands, and
  # returns an array of Cmd structs, fully connected and ready to be executed.
  #
  # Ex:
  #    > Parser.parse('foo | bar; baz < fizz.txt')
  #   => [
  #        <Cmd name='foo', ... >,
  #        <Cmd name='|', ... >,
  #        <Cmd name='bar' ... >,
  #        <Cmd name=';' ... >,
  #        <Cmd name='baz', ... >
  #      ]
  def self.parse(multi_cmd_str)
    io_connect(
      subcmds(multi_cmd_str).map{|c| cmd_from(c) }
    )
  end

  ##
  # Takes a string captured from a CLI containing one or more commands, and
  # returns an array of the commands within that string. Basically this splits
  # on tokens that appear between commands.
  #
  # Ex:
  #    > Parser.subcmds('foo | bar; baz < fizz.txt')
  #   => ["foo", "|", "bar", ";", "baz < fizz.txt"]
  def self.subcmds(multi_cmd_str)
    multi_cmd_str
      .split(/(&&|\*|\||;)/)
      .map{|cmd| cmd.strip }
  end

  ##
  # Takes a command string containing a single command, and returns a Cmd struct
  # containing the parts in the command.
  #
  # Ex:
  #    > Parser.cmd_from('baz < fizz.txt')
  #   => #<struct Cmd
  #         id="6ac8aa1c-fdc8-4a63-9b4b-8cd185bd0f40",
  #         name="baz",
  #         args="",
  #         input="fizz.txt",
  #         output=nil
  #       >
  def self.cmd_from(single_cmd_str)
    parts = parts_from(single_cmd_str)

    Cmd.new(
      SecureRandom.uuid,
      name(parts),
      args(parts),
      input(parts),
      output(parts)
    )
  end

  ##
  # Takes an array of Cmd structs and does two things with them:
  #
  # For every Cmd:
  #
  # - Sets the Cmd's #output attribute
  # - Looks for uses of the pipe ('|') command, and where found, connect the
  #   output of the Cmd preceding the pipe to the input of the Cmd following the
  #   pipe.
  #
  # The command string:
  #   'foo | bar'
  #
  # ... will be split into Cmd structs that represent 'foo', '|', and 'bar'.
  # This method notices that a pipe ('|') Cmd is being used, and connects the
  # output of 'foo' to the input of 'bar'.
  def self.io_connect(cmd_list)
    cmd_list[0][:output] ||= cmd_list[0][:id]
    cmd_list[1..-1].each.with_index do |c, i|
      c[:output] ||= c[:id]
      c[:input] ||= cmd_list[i - 1][:id] if cmd_list[i][:name].eql?('|')
    end

    cmd_list
  end

  ##
  # Takes a single command string and returns the component parts as an array of
  # strings.
  #
  # Ex:
  #    > Parser.parts_from('foo bar1 bar2 bar3 < baz > fizz')
  #   => ["foo", "bar1", "bar2", "bar3", "<", "baz", ">", "fizz"]
  #       name   |----- arguments -----| |- input -| |- output -|
  #
  # From this list, other supporting methods can extract the name, arguments,
  # input redirection, and output redirection.
  def self.parts_from(single_cmd_str)
    single_cmd_str
      .split(/(<|>)/)
      .map{|p| p.strip }
      .map{|p| p.split }
      .flatten
  end

  ##
  # Takes an array of the parts of a single command string and returns the name
  # portion.
  #
  # See ::parts_from.
  def self.name(parts)
    parts[0]
  end

  ##
  #  Takes an array of the parts of a single command string and returns the
  #  arguments portion.
  #
  #  See ::parts_from.
  def self.args(parts)
    end_index = [
      (parts.index('<') || parts.length + 1),
      (parts.index('>') || parts.length + 1),
      parts.length + 1
    ].compact.min - 1

    parts[1..end_index].join(' ')
  end

  ##
  # Takes an array of the parts of a single command string and returns the input
  # redirection portion.
  #
  # See ::parts_from.
  def self.input(parts)
    return nil unless parts.index('<')
    parts[parts.index('<') + 1]
  end

  ##
  # Takes an array of the parts of a single command string and returns the
  # output redirection portion.
  #
  # See ::parts_from.
  def self.output(parts)
    return nil unless parts.index('>')
    parts[parts.index('>') + 1]
  end
end
