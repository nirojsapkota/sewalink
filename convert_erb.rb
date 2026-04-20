
class File
  class << self
    alias_method :exists?, :exist?
  end
end

require 'html2slim/command'
HTML2Slim::Command.new(ARGV).run
