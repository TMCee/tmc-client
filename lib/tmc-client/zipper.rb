require 'zip'

module TmcClient
  module Zipper
    Zip.setup do |c|
      c.on_exists_proc = true
      c.continue_on_exists_proc = true
      c.unicode_names = true
    end


    def unzip_file (file, destination, exercise_dir_name)
      Zip::File.open(file) do |zip_file|
        zip_file.each do |f|
          merged_path = f.name.sub(exercise_dir_name.gsub("-", "/"), "")
          f_path=File.join(destination, exercise_dir_name, merged_path)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        end
      end
    end

    # Filepath can be either relative or absolute
    #
    # change behaviour to make this tmp_file
    # and destroy it when no longer needed
    def zip_file_content(filepath)
      zip_file(filepath, "tmp_submit.zip")
      #`zip -r -q tmp_submit.zip #{filepath}`
      #`zip -r -q - #{filepath}`
    end


    def zip_file(directory, zipfile_name)
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
          Dir[File.join(directory, '**', '**')].each do |file|
            zipfile.add(file.sub(directory, ''), file)
          end
      end
    end

    def update_from_zip(zip_url, exercise_dir_name, course_dir_name, exercise, course)
      zip = fetch_zip(zip_url)
      output.puts "URL: #{zip_url}"
      work_dir = Dir.pwd
      to_dir = if Dir.pwd.chomp("/").split("/").last == exercise_dir_name
        work_dir
      else
        File.join(work_dir, exercise_dir_name)
      end
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do
          File.open("tmp.zip", 'wb') {|file| file.write(zip.body)}
          #`unzip -n tmp.zip && rm tmp.zip`
          full_path = File.join(Dir.pwd, 'tmp.zip')
          unzip_file(full_path, Dir.pwd, exercise_dir_name)
          `rm tmp.zip`
          files = Dir.glob('**/*')
          all_selected = false
          files.each do |file|
            next if file == exercise_dir_name or File.directory? file
            output.puts "Want to update #{file}? Yn[A]" unless all_selected
            input = @input.gets.chomp.strip unless all_selected
            all_selected = true if input == "A" or input == "a"
            if all_selected or (["", "y", "Y"].include? input)
              begin
                to = File.join(to_dir,file.split("/")[1..-1].join("/"))
                output.puts "copying #{file} to #{to}"
                unless File.directory? to
                  FileUtils.mkdir_p(to.split("/")[0..-2].join("/"))
                else
                  FileUtils.mkdir_p(to)
                end
                FileUtils.cp_r(file, to)
              rescue ArgumentError => e
               output.puts "An error occurred #{e}"
             end
           else
            output.puts "Skipping file #{file}"
          end
        end
      end
    end
  end

  def update_automatically_detected_project_from_zip(zip_url, exercise_dir_name, course_dir_name, exercise, course)
    zip = fetch_zip(exercise['zip_url'])
    work_dir = Dir.pwd
    to_dir = if Dir.pwd.chomp("/").split("/").last == exercise_dir_name
      work_dir
    else
      File.join(work_dir, exercise_dir_name)
    end
    Dir.mktmpdir do |tmpdir|
      Dir.chdir tmpdir do
        File.open("tmp.zip", 'wb') {|file| file.write(zip.body)}
          # `unzip -n tmp.zip && rm tmp.zip`
          full_path = File.join(Dir.pwd, 'tmp.zip')
          unzip_file(full_path, Dir.pwd, exercise_dir_name)
          `rm tmp.zip`
          files = Dir.glob('**/*')

          files.each do |file|
            next if file == exercise_dir_name or file.to_s.include? "src" or File.directory? file
            begin
              to = File.join(to_dir,file.split("/")[1..-1].join("/"))
              output.puts "copying #{file} to #{to}"
              unless File.directory? to
                FileUtils.mkdir_p(to.split("/")[0..-2].join("/"))
              else
                FileUtils.mkdir_p(to)
              end
              FileUtils.cp_r(file, to)
            rescue ArgumentError => e
             output.puts "An error occurred #{e}"
           end
         end
       end
     end
   end

 end
end