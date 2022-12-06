# frozen_string_literal: true

def init
  if defined?(@file) && @file
    if @file.attributes[:namespace]
      @object = options.object = Registry.at(@file.attributes[:namespace]) || Registry.root
    end
    sections :diskfile
  elsif object.is_a?(CodeObjects::Base)
    unless object.root?
      cur = object.namespace
      cur = cur.namespace until cur.root?
    end

    type = object.root? ? :module : object.type
    sections T(type)
  end
end

def diskfile
  @file.contents
end
