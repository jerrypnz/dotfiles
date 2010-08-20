require 'pty'
require 'io/wait'

$VERBOSE=nil

class UnixPIO

  BUF_SIZE = 32767

  attr_reader :pid

  def initialize(command)
    @reader, @writer, @pid = PTY.spawn(command)
    @writer.sync = true
  end

  def write(text)
    @writer.puts(text)
  end

  def read
    buf = ""
    while @reader.ready?
      c = @reader.read(1)
      buf << c if c
      return buf if buf.length == BUF_SIZE
    end
    buf
  end

end


