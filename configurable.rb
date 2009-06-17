require 'ostruct'

module Configurable
  def config
    @config ||= OpenStruct.new
    yield @config if block_given?
  end
  def respond_to?(sym)
    @config.respond_to?(sym) || super(sym)
  end
  def method_missing(sym, *args, &block)
    if @config.respond_to?(sym)
      @config.send(sym, *args, &block)
    else
      super(sym, *args, &block)
    end
  end
end
