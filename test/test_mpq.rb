require 'helper'

class TestMPQ < Test::Unit::TestCase
  def setup
    @file = File.new File.join(File.dirname(__FILE__), "some.SC2Replay")
    @archive = MPQ::Archive.new @file
  end
  
  def teardown
    @file.close
  end
  
  def test_listfile
    assert @archive.read_file("(listfile)")["replay.details"]
  end
end
