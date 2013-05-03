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
  solution: :solution,
  get: :get,
  set: :set
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1

begin
  unless commands[command.to_sym].nil?
    @c.send(commands[command.to_sym], *sub_arguments) #unless command
  else
    puts "Unknown command"
  end
rescue
  puts "An error occurred. Make sure the command was triggered in the right directory. Also make sure you have a valid server address and authentication information. If these do not help, please contact an administrator."
end