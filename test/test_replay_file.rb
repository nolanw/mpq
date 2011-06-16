require 'replay_file'
require 'test/unit'
require 'time'

class TestReplayFile < Test::Unit::TestCase
  def setup
    @file = File.new File.join(File.dirname(__FILE__), "some.SC2Replay")
    @replay = MPQ::SC2ReplayFile.new @file
  end
  
  def teardown
    @file.close
  end
  
  def test_game_version
    assert_equal 1, @replay.game_version[:major]
    assert_equal 3, @replay.game_version[:minor]
    assert_equal 18317, @replay.game_version[:build]
  end
  
  def test_game_length
    assert_equal 1260, @replay.game_length
  end
  
  def test_players
    names = @replay.players.map{|p| p[:name]}
    assert names.include? "ESCGoOdy"
    goody = @replay.players[names.index "ESCGoOdy"]
    assert_equal :terran, goody[:race]
    assert_equal :purple, goody[:color]
    assert_equal :human, goody[:type]
  end
  
  def test_map_name
    assert_equal "The Shattered Temple", @replay.map_name
  end
  
  def test_start_date
    # FIXME: should be parsed as UTC, and this test should reflect that.
    assert (Time.parse("2011-04-24 10:09:18 -0600") - 
            @replay.start_date).abs < 1
  end
  
  def test_realm
    assert_equal "EU", @replay.realm
  end
  
  def test_game_type
    assert_equal :"1v1", @replay.game_type
  end
  
  def test_game_speed
    assert_equal :faster, @replay.game_speed
  end
  
  def test_category
    assert_equal :private, @replay.category
  end
end
