require_relative '../lib/tmc-client/client.rb'
require 'rspec'
require 'mocha'

describe Client do
  subject do
    Client.new
  end

  before(:each) do
    subject.config = MyConfig.new
  end

  its(:current_directory_name) { should ==  `pwd`.split("/").last.chomp }
  its(:previous_directory_name) { should == `pwd`.split("/")[-2].chomp }

  it "should be able to produce some zip contents" do
    file = Tempfile.new("tmp")
    file.write("content")
    file.close
    subject.zip_file_content(file.path)
    zip_content = File.read("tmp_submit.zip")
    `rm tmp_submit.zip`
    file.unlink

    zip_content.should_not be_nil
    zip_content.should_not == ""
  end
end