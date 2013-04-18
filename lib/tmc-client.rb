require_relative 'tmc-client/client'

@c = Client.new

commands = {
  list: :list,
  download: :download,
  submit: :submit_exercise,
  update: :update_exercise,
  auth: :auth,
  init: :init_course
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1
@c.send(commands[command.to_sym], *sub_arguments)