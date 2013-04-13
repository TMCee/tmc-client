require_relative 'lib/client'

@c = Client.new

commands = {
  list: :list,
  download: :download_all_available,
  submit: :submit_exercise,
  update: :update_exercise
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1
@c.send(commands[command.to_sym], *sub_arguments)