require 'spec_helper'


TmcClient::Client.class_eval do
  def setup_client
  end
end

describe TmcClient::Client do
  subject do
    TmcClient::Client.new
  end

  before(:each) do
    subject.config = TmcClient::MyConfig.new
  end

  its(:current_directory_name) { should ==  `pwd`.split("/").last.chomp }
  its(:previous_directory_name) { should == `pwd`.split("/")[-2].chomp }

  it "should be able to produce some zip contents" do
    file = Tempfile.new("tmp")
    file.write("content")
    file.close
    subject.zip_file_content(file.path)
    zip_content = File.read("tmp_submit.zip")
    `rm tmp_submit.zip 2>&1 /dev/null`
    file.unlink

    zip_content.should_not be_nil
    zip_content.should_not == ""
  end
end