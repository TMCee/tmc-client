require_relative '../lib/client.rb'
require 'tempfile'

describe Client do
  subject { Client.new }

  its(:current_directory_name) { should ==  `pwd`.split("/").last.chomp }
  its(:previous_directory_name) { should == `pwd`.split("/")[-2].chomp }

  it "should return be able to produce some zip contents" do
    file = Tempfile.new("tmp")
    file.write("content")
    file.close
    zip_content = subject.zip_file_content(file.path)
    file.unlink

    zip_content.should_not be_nil
  end

  it "should finish submitting and return the sent payload"
end