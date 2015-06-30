#!/usr/bin/env ruby
require 'optparse'

require 'cassandra'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: verifykeys.rb [options] [file...]"

  options[:verbose] = false
  opts.on('-v', '--verbose', 'Print verification staus of all keys') do
    options[:verbose] = true
  end

  options[:hosts] = ["127.0.0.1"]
  opts.on('-d', '--nodes node1,node2,node3', Array,
      'Connect to the (comma separated) list of nodes') do |nodes|
    options[:hosts] = nodes
  end

  options[:port] = 9042
  opts.on('-p', '--port PORT', 'Connect to the given port') do |port|
    options[:port] = port
  end

  opts.on('-k', '--keyspace KS', 'Check against the given keyspace') do |ks|
    options[:ks] = ks
  end

  opts.on('-t', '--table TABLE', 'Check against the given table') do |table|
    options[:table] = table
  end

  options[:partition] = "name"
  opts.on('-r', '--partition COLUMN',
      'Use the given column as the partition key') do |column|
    options[:partition] = column
  end

  options[:quick] = false
  opts.on('-q', '--quick', 'Exit immediately if a key is not found') do |quick|
    options[:quick] = quick
  end

  opts.on('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end
optparse.parse!

cluster = Cassandra.cluster(
  hosts: options[:hosts],
  port:  options[:port],
)

keyspace = options[:ks]
table = options[:table]

if !keyspace || !table then
  # Try to infer from the filename, if given
  fname = ARGF.argv[0]
  if fname then
    portions = fname.split(".")
    if portions.length >= 2 then
      keyspace = portions[0] if not keyspace
      table = portions[1] if not table
    end
  end
end

raise "Keyspace and table must be specified!" if !(keyspace && table)

session  = cluster.connect(options[:keyspace])
key = options[:partition]

fetch = "SELECT * FROM #{keyspace}.#{table} WHERE #{key}=? LIMIT 1"
prepped = session.prepare(fetch)
okay = true

ARGF.each do |line|
  line = line.strip
  key = [line].pack("H*")  # Currently assuming all keys are strings
  results = session.execute(prepped.bind([key]))
  if results.empty? then
    okay = false
    puts "Key '#{key}' (raw: #{line}) NOT found"
    exit false if options[:quick]
  else
    puts "Key '#{key}' (raw: #{line}) found" if options[:verbose]
  end
end

exit okay
