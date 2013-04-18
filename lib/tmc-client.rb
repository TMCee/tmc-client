require_relative 'tmc-client/client'

@c = Client.new

commands = {
  list: :list,
  download: :download_new_exercises,
  submit: :submit_exercise,
  update: :update_exercise,
  auth: :auth
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1
@c.send(commands[command.to_sym], *sub_arguments)