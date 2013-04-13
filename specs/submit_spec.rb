require_relative '../lib/client.rb'
require 'rspec'
require 'mocha'

describe Client do
  subject do
    Client.new
  end

  its(:current_directory_name) { should ==  `pwd`.split("/").last.chomp }
  its(:previous_directory_name) { should == `pwd`.split("/")[-2].chomp }

  it "should be able to produce some zip contents" do
    file = Tempfile.new("tmp")
    file.write("content")
    file.close
    zip_content = subject.zip_file_content(file.path)
    file.unlink

    zip_content.should_not be_nil
  end

  it "should send data with conn object" do
    mock_object = mock("conn")
    mock_object.expects(:post).returns(true)
    subject.conn = mock_object
    subject.submit_exercise
  end
end