require_relative 'lib/client'

@c = Client.new

commands = {
  list: :list,
  download: :download,
  submit: :submit_exercise
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1
c.send(command, *sub_arguments)