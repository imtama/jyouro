require "jyouro/version"
require "active_support"

module Jyouro
  class << self
    def left_to_the_gardener
      raise NotImplementedError
    end

    def water(name, io: $stderr, &block)
      # store arguments
      setup(name, io, block)
      validate_arguments! rescue raise $!
      puts_start_message_if_first_time

      set_seeds_by_yielding_block
      validate_water_block! rescue raise $!
      water_seeds

      puts_result
    end
    alias watering water

  private
    def setup(name, io, block)
      @name, @io, @block = name, io, block
      @table = @name.to_s.tableize
      @model = @name.to_s.classify.constantize
    end

    def validate_arguments!
      raise ArgumentError.new("provide name of table to Jyouro.water") if @name.blank?
      raise ArgumentError.new("provide seed data as a block to Jyouro.water") if @block.nil?
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
      message = "  #{@table}:\t#{@count_after}\t(+ #{dif} / #{@seeds.size})"
      @io.puts message
    end

    def set_seeds_by_yielding_block
      @seeds = @block.yield
    end

    def validate_water_block!
      raise ArgumentError.new(message_water_block) unless @seeds.respond_to?(:each)
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

    def message_water_block
      "Provide an Array or Hash (or Array-like) object to the block of Jyouro.water"
    end

    def message_seed_error(err, obj:)
      <<~EOS
        ERROR raised for `#{@table}`
          Exception:\t#{err.class}
          Message:\t#{err.message}
          Reason:\t#{err.cause}
          Object:\t#{obj.inspect}
      EOS
    end

    def red(text)
      "\e[31m#{text}\e[0m"
    end
  end
 end
