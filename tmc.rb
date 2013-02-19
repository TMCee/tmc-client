require_relative 'lib/client'

@c = Client.new

def select_course
  @c.ask_for_course_id
end

def list_exercises
  @c.list_exercises
end

def list_active
  @c.list_active
end

def download_all_available
  @c.download_all_available
end

def submit_exercise
  @c.submit_exercise
end

def list(mode)
  if mode.nil?
    puts "What would you like to list? Perhaps exercises with list exercises, or active projects with list active?"
    return
  end

  send("list_#{mode}")
end

commands = {
  list: :list,
  download: :download,
  submit: :submit_exercise
}

command = ARGV[0].to_s
sub_arguments = ARGV.drop 1
send(command, *sub_arguments)