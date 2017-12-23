require "jyouro/version"
# require "active_support"
# require "active_support/inflector"

module Jyouro
  class << self
    # @param  [String | Symbol]  name  name of model (or table), both singular and plural forms are acceptable
    # @option [:block | :file | String]  from:  source of seed data. if :file or String or given, Jyouro loads it from file.
    # @option [IO]  io:  IO object like $stdout, $stderr
    def water(name, from: :block, io: $stderr, &block)
      @t0 = Time.now
      # store arguments
      setup(name, from, io, block)
      set_mode
      validate_arguments! rescue raise $!
      puts_start_message_if_first_time

      if mode_block?
        set_seeds_by_yielding_block
        validate_water_block! rescue raise $!
      elsif mode_file? or mode_file_auto_detect?
        set_seeds_from_yml_file
      end

      # Now is the time, let's water seeds
      water_seeds

      puts_result
    end

  private
    def setup(name, from, io, block)
      @name, @from, @io, @block = name, from, io, block
      @table = @name.to_s.tableize
      @model = @name.to_s.classify.constantize
    end

    def set_mode
      if :block == @from.to_sym
        mode_block!
      elsif :file == @from.to_sym
        mode_file_auto_detect!
      elsif String == @from.class
        mode_file!
      else
        mode_unknown!
      end
    end

    [:block, :file_auto_detect, :file, :unknown].each do |mode|
      define_method "mode_#{mode}!" do @mode =  mode end
      define_method "mode_#{mode}?" do @mode == mode end
    end

    def validate_arguments!
      if @name.blank?
        raise ArgumentError.new("provide name of table to Jyouro.water")
      end
      if mode_unknown?
        message = <<~EOS
          Provide valid value for `from:`. you can use [ :block | :file | String ]
            :block  -->  Jyouro loads seed data from the block of Jyouro.water (default)
            :file   -->  You can put yaml file on `/db/seeds/<TABLE_NAME>.yml`, Jyouro loads it. Notice that ERB works in yaml.
            "/path/to/yaml/file"  -->  Similar to :file, but you can specify the path to yaml file. Path should be relative to Rails' root.
        EOS
        raise InvalidArgumentError.new(message)
      end
      if (@mode == :block) and @block.nil?
        raise ArgumentError.new("provide seed data as a block to Jyouro.water")
      end
    end

    def puts_start_message_if_first_time
      unless @__once_puts_start_message_if_first_time
        @__once_puts_start_message_if_first_time = true
        @io.puts "Adding seed data..."
      end
    end

    def puts_result
      unless @__once_puts_result
        @__once_puts_result = true
        @io.puts "# of records\t\t(+ added / seeds)"
      end
      dif = @count_after - @count_before
      time = Time.now - @t0

      message = "  #{@table}:\t#{@count_after}\t(+ #{dif} / #{@seeds.size})\t#{time.round(3)} sec"
      @io.puts message
    end

    def set_seeds_by_yielding_block
      @seeds = @block.yield
    end

    def set_seeds_from_yml_file
      erb_data = File.open(build_file_path).read
      yml_data = ERB.new(erb_data).result
      yml_obj  = YAML.load(yml_data)
      # We simply drop labels of seed data (sorry)
      @seeds = yml_obj.values
    end

    def build_file_path
      if mode_file_auto_detect?
        Rails.root.join("db/seeds/#{@table}.yml")
      else
        Rails.root.join(@from)
      end
    end

    def validate_water_block!
      unless @seeds.respond_to?(:each)
        message = "Provide an Array or Hash (or Array-like) object to the block of Jyouro.water"
        raise ArgumentError.new(message)
      end
    end

    def water_seeds
      @count_before = @model.count

      @seeds.each do |seed|
        begin
          if option = seed.delete(:Jyouro)
            # @model.find_or_initialize_by(seed).save(option)
            @model.new(seed).save!(option)
          else
            # @model.find_or_create_by(seed)
            @model.create!(seed)
          end
        rescue => err
          @io.puts red(message_seed_error(err, obj: seed))
        end
      end

      @count_after = @model.count
    end

    def message_seed_error(err, obj:)
      <<~EOS
        ERROR raised for `#{@table}`
          Exception:\t#{err.class}
          Message:\t#{err.message}
          Reason:\t#{err.cause}
          Object:\t#{obj.inspect}
          Backtrace:\n\t#{err.backtrace.join("\n\t")}
      EOS
    end

    def red(text)
      "\e[31m#{text}\e[0m"
    end
  end
 end
