require 'core_ext/module/anonymous'
require 'core_ext/string/inflections'

class Module
  def reachable? #:nodoc:
    !anonymous? && name.safe_constantize.equal?(self)
  end
end