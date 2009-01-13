# http://blog.lawrencepit.com/2009/01/11/try-as-you-might/
class Object
  def try(method, *args, &block)
    send(method, *args, &block) unless self.nil?
  end
end
