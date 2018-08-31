# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'rbconfig'
#Dir[File.dirname(__FILE__) + '*.rb'].each {|file| puts file; require file }

# Class for mofifyiung of RISM OPAC at BSB
module Marcxml
  class OENB < Transformator
    include Logging
    attr_accessor :node, :namespace, :methods
    def initialize(node, namespace={'marc' => "http://www.loc.gov/MARC21/slim"})
      @namespace = namespace
      @node = node
      @methods =  [:extract_controlfields]
    end

    def extract_controlfields

    end

  end
end

