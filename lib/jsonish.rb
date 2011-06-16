# MPQ files store some data in a serialized format that's strikingly similar to 
# JSON, so I've called it **JSONish**. It's a fairly simple format, documented 
# at http://github.com/GraylinKim/sc2reader/wiki/serialized.data and at 
# http://teamliquid.net/forum/viewmessage.php?topic_id=117260&currentpage=3#45.
module MPQ
  module JSONish
    
    # `parse` is the public API here, the following two methods are simply 
    # helpers.
    def self.parse data
      self.parse_recur String.new data
    end
  
    # JSONish consists of strings, arrays, maps, and integers. The first byte 
    # of each of these indicates which is about to follow.
    def self.parse_recur data
      case data.slice!(0).bytes.next
    
      # `02` indicates a string. The next byte is a variable-length integer 
      # (see below) indicating the string's length, and the remaining bytes are 
      # the string itself.
      when 2
        data.slice! 0, vlf(data)
    
      # `04` is an array, a list of values. Each value indicates its type, so 
      # this is largely just a recursive process.
      when 4
        data.slice! 0, 2
        (0...vlf(data)).map {|i| parse_recur data }
    
      # `05` starts a map, also known as a Hash or an object literal. It maps 
      # keys to values. In JSONish, keys are always variable-length integers, 
      # while values can be anything.
      when 5
        Hash.[]((0...vlf(data)).map do |i| 
          [vlf(data), parse_recur(data)]
        end)
    
      # `06` is a single-byte integer.
      when 6
        data.slice! 0
    
      # `07` is a four-byte integer in little-endian format.
      when 7
        data.slice!(0, 4).unpack("V")[0]
    
      # `09` is a standalone (i.e. not a key or length) variable-length integer.
      when 9
        vlf data
    
      # If there are other types in JSONish, we don't know about them.
      else
        nil
      end
    end
  
    # A variable-length integer is a concise serialization of an 
    # arbitrary-precision integer. Each byte (except the last) sets the high bit 
    # to `1` to indicate that the next byte is included in the integer. Seven 
    # bits of each byte, plus all eight bits of the final byte, make up the 
    # final number in little-endian format.
    def self.vlf data
      ret, shift = 0, 0
      loop do
        char = data.slice!(0)
        return nil unless char
        byte = char.bytes.next
        ret += (byte & 0x7F) << (7 * shift)
        break if byte & 0x80 == 0
        shift += 1
      end
      (ret >> 1) * ((ret & 0x1) == 0 ? 1 : -1)
    end
  end
end
