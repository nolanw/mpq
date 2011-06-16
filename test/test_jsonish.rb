$:.unshift File.expand_path(File.join File.dirname(__FILE__), '..', 'src')
require "jsonish"
require "test/unit"

class TestJSONish < Test::Unit::TestCase
  def test_vlf
    assert_equal 0,        MPQ::JSONish.vlf("\x00")
    assert_equal 0,        MPQ::JSONish.vlf("\x01")
    assert_equal 1,        MPQ::JSONish.vlf("\x02")
    assert_equal -1,       MPQ::JSONish.vlf("\x03")
    assert_equal 2,        MPQ::JSONish.vlf("\x04")
    assert_equal 63,       MPQ::JSONish.vlf("\x7e")
    assert_equal -63,      MPQ::JSONish.vlf("\x7f")
    assert_equal nil,      MPQ::JSONish.vlf("\x80")
    assert_equal 0,        MPQ::JSONish.vlf("\x80\x00")
    assert_equal 64,       MPQ::JSONish.vlf("\x80\x01")
    assert_equal -64,      MPQ::JSONish.vlf("\x81\x01")
    assert_equal 65,       MPQ::JSONish.vlf("\x82\x01")
    assert_equal 128,      MPQ::JSONish.vlf("\x80\x02")
    assert_equal -128,     MPQ::JSONish.vlf("\x81\x02")
    assert_equal 18092,    MPQ::JSONish.vlf("\xd8\x9a\x02")
    assert_equal 18317,    MPQ::JSONish.vlf("\x9a\x9e\x02")
    assert_equal 16777216, MPQ::JSONish.vlf("\x80\x80\x80\x10")
  end
  
  def test_parse
    assert_equal "hi", MPQ::JSONish.parse("\x02\x04\x68\x69")
    assert_equal "Pille", MPQ::JSONish.parse("\x02\x0a\x50\x69\x6c\x6c\x65")
    assert_equal(["Pille", "\x2a", "\xa6", "\x8d"], 
      MPQ::JSONish.parse("\x04\x00\x01\x08\x02\x0A\x50\x69\x6C\x6C\x65" +
                    "\x06\x2A\x06\xA6\x06\x8D"))
    assert_equal({0 => "hi"}, 
      MPQ::JSONish.parse("\x05\x02\x00\x02\x04\x68\x69"))
    assert_equal({0 => "hi", 1 => "hi"}, 
      MPQ::JSONish.parse("\x05\x04\x00\x02\x04\x68\x69\x02\x02\x04\x68\x69"))
    assert_equal({0 => 1, 1 => 2, 4 => 3}, 
      MPQ::JSONish.parse("\x05\x06\x00\x09\x02\x02\x09\x04\x08\x09\x06"))
    assert_equal 76, MPQ::JSONish.parse("\x06\x4C").ord
  end
end
