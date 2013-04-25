require_relative 'tmc-client/client'

@c = Client.new

commands = {
  list: :list,
  download: :download,
  submit: :submit_exercise,
  update: :update_exercise,
  auth: :auth,
  check: :check,
  init: :init_course,
  status: :status,
  solution: :solution
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1

@c.send(commands[command.to_sym], *sub_arguments) #unless command