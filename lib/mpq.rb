# Read files and metadata from MPQ archives.
# 
# We'll use `bindata` as a DSL for binary extraction, and since we only care 
# about StarCraft 2 replays at the moment, the only decompression we need is 
# `bzip2`.
require 'bindata'
require 'bzip2'

# A massive thanks to Justin Olbrantz (Quantam) and Jean-Francois Roy 
# (BahamutZERO), whose [documentation of the MPQ 
# format](http://wiki.devklog.net/index.php?title=The_MoPaQ_Archive_Format) was 
# instrumental for this implementation.
# 
# Thanks to Aku Kotkavuo (arkx) for [mpyq](https://github.com/arkx/mpyq), which
# clarified a bunch of the implementation details that I couldn't distill from 
# the documentation mentioned above.
module MPQ
  class Archive
    
    # In general, MPQ archives start with either the MPQ header, or they start 
    # with a user header which points to the MPQ header. StarCraft 2 replays 
    # always have a user header, so we don't even bother to check here.
    # 
    # The MPQ header points to two very helpful parts of the MPQ archive: the 
    # hash table, which tells us where the contents of files are found, and the 
    # block table, which holds said contents of files. That's all we need to 
    # read up front.
    def initialize io
      @io = io
      @user_header = UserHeader.read @io
      @io.seek @user_header.archive_header_offset
      @archive_header = ArchiveHeader.read @io
      @hash_table = read_table :hash
      @block_table = read_table :block
    end
    
    # Both the hash and block tables' contents are hashed (in the same way), so 
    # we need to decrypt them in order to read their contents.
    def read_table table
      table_offset = @archive_header.send "#{table}_table_offset"
      @io.seek @user_header.archive_header_offset + table_offset
      table_entries = @archive_header.send "#{table}_table_entries"
      data = @io.read table_entries * 16
      key = Hashing::hash_for :table, "(#{table} table)"
      data = Hashing::decrypt data, key
      klass = table == :hash ? HashTableEntry : BlockTableEntry
      (0...table_entries).map do |i|
        klass.read(data[i * 16, 16])
      end
    end
    
    # To read a file from the MPQ archive, we need to locate its blocks.
    def read_file filename
      
      # The first block location is stored in the hash table.
      hash_a = Hashing::hash_for :hash_a, filename
      hash_b = Hashing::hash_for :hash_b, filename
      hash_entry = @hash_table.find do |h|
        [h.hash_a, h.hash_b] == [hash_a, hash_b]
      end
      unless hash_entry
        return nil
      end
      block_entry = @block_table[hash_entry.block_index]
      unless block_entry.file?
        return nil 
      end
      @io.seek @user_header.archive_header_offset + block_entry.block_offset
      file_data = @io.read block_entry.archived_size
      
      # Blocks can be encrypted. Decryption isn't currently implemented as none 
      # of the blocks in a StarCraft 2 replay are encrypted.
      if block_entry.encrypted?
        return nil
      end
      
      # Files can consist of one or many blocks. In either case, each block 
      # (or *sector*) is read and individually decompressed if needed, then 
      # stitched together for the final result.
      if block_entry.single_unit?
        if block_entry.compressed?
          if file_data.bytes.next == 16
            file_data = Bzip2.uncompress file_data[1, file_data.length]
          end
        end
        return file_data 
      end
      sector_size = 512 << @archive_header.sector_size_shift
      sectors = block_entry.size / sector_size + 1
      if block_entry.has_checksums
        sectors += 1
      end
      positions = file_data[0, 4 * (sectors + 1)].unpack "V#{sectors + 1}"
      sectors = []
      positions.each_with_index do |pos, i|
        break if i + 1 == positions.length
        sector = file_data[pos, positions[i + 1] - pos]
        if block_entry.compressed?
          if block_entry.size > block_entry.archived_size
            if sector.bytes.next == 16
              sector = Bzip2.uncompress sector
            end
          end
        end
        sectors << sector
      end
      sectors.join ''
    end
  end
  
  # Various hashes are used throughout MPQ archives.
  module Hashing
    
    # The algorithm is unchanged across hash types, but the first step in the 
    # hashing differs depending on what we're hashing.
    # 
    # Both this hashing and the decryption below make use of a precalculated 
    # table of values.
    def self.hash_for hash_type, s
      hash_type = [:table_offset, :hash_a, :hash_b, :table].index hash_type
      seed1, seed2 = 0x7FED7FED, 0xEEEEEEEE
      s.upcase.each_byte do |c|
        value = @encryption_table[(hash_type << 8) + c]
        
        # The seemingly pointless `AND`ing by 32 ones is because Ruby's numbers 
        # are arbitrary precision. Normally that's great, but right now that's 
        # actually unhelpful.
        seed1 = (value ^ (seed1 + seed2)) & 0xFFFFFFFF
        seed2 = (c + seed1 + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
      end
      seed1
    end
    
    # Data in the hash and block tables can be decrypted using this algorithm.
    def self.decrypt data, seed1
      seed2 = 0xEEEEEEEE
      data.unpack('V*').map do |value|
        
        # Again, the `AND`s here forces 32-bit precision.
        seed2 = (seed2 + @encryption_table[0x400 + (seed1 & 0xFF)]) & 0xFFFFFFFF
        value = (value ^ (seed1 + seed2)) & 0xFFFFFFFF
        seed1 = (((~seed1 << 0x15) + 0x11111111) | (seed1 >> 0x0B)) & 0xFFFFFFFF
        seed2 = (value + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
        value
      end.pack('V*')
    end
    
    # This table is used for the above hashing and decryption routines.
    seed = 0x00100001
    @encryption_table = {}
    (0..255).each do |i|
      index = i
      (0..4).each do |j|
        seed = (seed * 125 + 3) % 0x2AAAAB
        tmp1 = (seed & 0xFFFF) << 0x10
        seed = (seed * 125 + 3) % 0x2AAAAB
        tmp2 = (seed & 0xFFFF)
        @encryption_table[i + j * 0x100] = (tmp1 | tmp2)
      end
    end
  end
  
  # The layout of the user header, an optional part of MPQ archives. If it's 
  # present, it must be at the beginning of the archive.
  class UserHeader < BinData::Record
    endian :little
    
    # This magic value is always the same: `MPQ\x1b`.
    string :user_magic, :length => 4
    uint32 :user_data_max_length
    uint32 :archive_header_offset
    uint32 :user_data_length
    string :user_data, :length => :user_data_length
  end
  
  # All MPQ archives have an archive header. It's located at the start of the 
  # archive, unless a user header is there, in which case the user header
  # points to the location of this archive header.
  class ArchiveHeader < BinData::Record
    endian :little
    
    # This magic value is always the same: `MPQ\x1a`.
    string :archive_magic, :length => 4
    int32  :header_size
    int32  :archive_size
    int16  :format_version
    int8   :sector_size_shift
    int8
    int32  :hash_table_offset
    int32  :block_table_offset
    int32  :hash_table_entries
    int32  :block_table_entries
    int64  :extended_block_table_offset
    int16  :hash_table_offset_high
    int16  :block_table_offset_high
  end
  
  # Each hash table entry follows this format. No idea what the spare byte is 
  # for.
  class HashTableEntry < BinData::Record
    endian :little
  
    uint32 :hash_a
    uint32 :hash_b
    int16  :language
    int8   :platform
    int8
    int32  :block_index
  end
  
  # Each block table follows this format. Although `BinData` can handle 
  # bitfields (`flags` in this case), I had problems setting them up, so I 
  # settled for methods instead.
  class BlockTableEntry < BinData::Record
    endian :little
  
    int32  :block_offset
    int32  :archived_size
    int32  :file_size
    uint32 :flags
  
    def file?
      (flags & 0x80000000) != 0
    end
    
    def compressed?
      (flags & 0x00000200) != 0
    end
  
    def encrypted?
      (flags & 0x00010000) != 0
    end
  
    def single_unit?
      (flags & 0x01000000) != 0
    end
  end
end
