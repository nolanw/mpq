# StarCraft 2 replay files are MPQ archives, with some data serialized as what 
# I'm calling *JSONish*. We also use `bindata` as a DSL for some of the file 
# contents.
require 'bindata'
require 'mpq'
require 'jsonish'

module MPQ
  class SC2ReplayFile < Archive
  
    # Game length is given as the number of frames.
    def game_length
      @game_length ||= user_data[3] / FRAMES_PER_SECOND
    end
  
    # These are the numbers you see in the bottom left of the game's menu. Use 
    # the `build` to change features, etc. based on game version. Use the rest 
    # when presenting a version to a person.
    def game_version
      @game_version ||= {
        :major => user_data[1][1],
        :minor => user_data[1][2],
        :patch => user_data[1][3],
        :build => user_data[1][4]
      }
    end
  
    # Player information is spread among a couple of files: the 
    # `replay.details` file and the `replay.attributes.events` file. Here we 
    # combine the information contained in each.
    def players
      return @players if defined? @players
      @players = details[0].map do |player|
        { :name => player[0],
        
          # This could probably be 'unknown' in some circumstances I haven't 
          # yet checked.
          :outcome => OUTCOMES[player[8]]
        }
      end
    
      # Unlike the `replay.initData` file, this method of determining race is
      # the same across all localizations.
      attributes.each do |attr|
        case attr.id.to_i
        when 0x01f4
          @players[attr.player - 1][:type] = ATTRIBUTES[:player_type][attr.sval]
        when 0x0bb9
          @players[attr.player - 1][:race] = ATTRIBUTES[:player_race][attr.sval]
        when 0x0bba
          @players[attr.player - 1][:color] = 
            ATTRIBUTES[:player_color][attr.sval]
        end
      end
      @players
    end
  
    # The localized map name. Should probably translate it.
    def map_name
      details[1]
    end
  
    # The start date of the game, probably off by a time zone or ten.
    def start_date
=begin
      FIXME: parse this as UTC (possibly requires use of time zone offset 
      present in details).
=end
      Time.at((details[5] - 116444735995904000) / 1e7)
    end
  
    # Two-uppercase-character abbreviation, like `NA`.
    def realm
      initdata.rest.split('s2ma')[1][2, 2]
    end
  
    # Each of these getters are for information contained in the 
    # `replay.attributes.events` file, but their exact position cannot be 
    # assumed from file to file, so we might as well extract them all when 
    # asked for any one of them.
    %w[game_type game_speed category].each do |lazy_getter|
      class_eval <<-EVAL
        def #{lazy_getter}
          parse_global_attributes unless defined? @#{lazy_getter}
          @#{lazy_getter}
        end
      EVAL
    end
  
    # Wrappers for deserializing some JSONish.
    private
    def user_data
      @user_data ||= JSONish.parse @user_header.user_data
    end
  
    def details
      @details ||= JSONish.parse read_file "replay.details"
    end
  
    # `replay.initData` has some useful information, but almost all of it can 
    # be more reliably obtained elsewhere. All that's really useful here is the 
    # realm the game was played in.
    def initdata
      @initdata ||= InitData.read read_file "replay.initData"
    end
  
    class InitData < BinData::Record
      uint8 :num_players
      array :players, :initial_length => :num_players do
        uint8 :player_name_length
        string :player_name, :length => :player_name_length
        skip :length => 5
      end
      string :unknown_24, :length => 24
      uint8 :account_length
      string :account, :length => :account_length
      rest :rest
    end
  
    # `replay.attributes.events` has plenty of handy information. Here we 
    # simply deserialize all the attributes, taking into account a format 
    # change that took place in build 17326, for later processing.
    def attributes
      return @attributes if defined? @attributes
      data = read_file "replay.attributes.events"
      data.slice! 0, (game_version[:build] < 17326 ? 4 : 5)
      @attributes = []
      data.slice!(0, 4).unpack("V")[0].times do
        @attributes << Attribute.read(data.slice!(0, 13))
      end
      @attributes
    end
  
    class Attribute < BinData::Record
      endian :little
    
      string :header, :length => 4
      uint32 :id
      uint8  :player
      string :val, :length => 4
    
      def sval
        val.reverse
      end
    end
  
    # Several pieces of information come from `replay.attributes.events`, and 
    # finding one of them is about as hard as finding all of them, so we just 
    # find all of them here when asked.
    def parse_global_attributes
      attributes.each do |attr|
        case attr.id.to_i
        when 0x07d1
          @game_type = attr.sval
          @game_type = @game_type == 'Cust' ? :custom : @game_type[1, 3].to_sym
        when 0x0bb8
          @game_speed = ATTRIBUTES[:game_speed][attr.sval]
        when 0x0bc1
          @category = ATTRIBUTES[:category][attr.sval]
        end
      end
    end
  end
end

# Some translations for various values in replays.
FRAMES_PER_SECOND = 16
OUTCOMES = [:unknown, :win, :loss]
ATTRIBUTES = {
  :player_type => {"Humn" => :human, "Comp" => :computer},
  :player_race => {
    "RAND" => :random, "Terr" => :terran, "Prot" => :protoss, "Zerg" => :zerg
  },
  :player_color => {
    "tc01" => :red,
    "tc02" => :blue,
    "tc03" => :teal,
    "tc04" => :purple,
    "tc05" => :yellow,
    "tc06" => :orange,
    "tc07" => :green,
    "tc08" => :light_pink,
    "tc09" => :violet,
    "tc10" => :light_grey,
    "tc11" => :dark_green,
    "tc12" => :brown,
    "tc13" => :light_green,
    "tc14" => :dark_grey,
    "tc15" => :pink
  },
  :game_speed => {
    "Slor" => :slower,
    "Slow" => :slow,
    "Norm" => :normal,
    "Fast" => :fast,
    "Fasr" => :faster
  },
  :category => {
    "Priv" => :private,
    
    # `Amm` is assumed to stand for "automatic matchmaker".
    "Amm" => :ladder,
    "Pub" => :public
  }
}
