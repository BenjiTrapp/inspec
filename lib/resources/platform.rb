# encoding: utf-8

module Inspec::Resources
  class PlatformResource < Inspec.resource(1)
    name 'platform'
    desc 'Use the platform InSpec resource to test the platform on which the system is running.'
    example "
      describe platform do
        its('name') { should eq 'redhat' }
      end

      describe platform do
        it { should be_in_family('unix') }
      end
    "

    def initialize
      @platform = inspec.backend.os
    end

    # add helper methods for easy access of properties
    %w{family release arch}.each do |property|
      define_method(property.to_sym) do
        @platform.send(property)
      end
    end

    # This is a string override for platform.name.
    # TODO: removed in inspec 2.0
    class NameCleaned < String
      def ==(other)
        if other =~ /[A-Z ]/
          cleaned = other.downcase.tr(' ', '_')
          Inspec::Log.warn "[DEPRECATED] Platform names will become lowercase in InSpec 2.0. Please match on '#{cleaned}' instead of '#{other}'"
          super(cleaned)
        else
          super(other)
        end
      end
    end

    def name
      NameCleaned.new(@platform.name)
    end

    def [](key)
      # convert string to symbol
      key = key.to_sym if key.is_a? String
      return name if key == :name

      @platform[key]
    end

    def platform?(name)
      @platform.name == name ||
        @platform.family_hierarchy.include?(name)
    end

    def in_family?(family)
      @platform.family_hierarchy.include?(family)
    end

    def families
      @platform.family_hierarchy
    end

    def supported?(supports)
      return true if supports.nil? || supports.empty?

      status = true
      supports.each do |s|
        s.each do |k, v|
          # ignore the inspec check for supports
          # TODO: remove in inspec 2.0
          if k == :inspec
            next
          elsif %i(os_family os-family platform_family platform-family).include?(k)
            status = in_family?(v)
          elsif %i(os platform).include?(k)
            status = platform?(v)
          elsif %i(os_name os-name platform_name platform-name).include?(k)
            status = name == v
          elsif k == :release
            status = check_release(v)
          else
            status = false
          end
          break if status == false
        end
        return true if status == true
      end

      status
    end

    def to_s
      'Platform Detection'
    end

    private

    def check_release(value)
      # allow wild card matching
      if value.include?('*')
        cleaned = Regexp.escape(value).gsub('\*', '.*?')
        !(release =~ /#{cleaned}/).nil?
      else
        release == value
      end
    end
  end
end
