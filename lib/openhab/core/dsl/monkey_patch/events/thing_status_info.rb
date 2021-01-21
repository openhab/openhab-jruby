# frozen_string_literal: true

require 'java'

#
# Monkey patch with ruby style accessors
#
# rubocop:disable Style/ClassAndModuleChildren
class Java::OrgOpenhabCoreThingEvents::ThingStatusInfoChangedEvent
  # rubocop:enable Style/ClassAndModuleChildren

  alias uid get_thing_uid
  alias last get_old_status_info
  alias status status_info
end

#
# Monkey patch with ruby style accessors
#
# rubocop:disable Style/ClassAndModuleChildren
class Java::OrgOpenhabCoreThingEvents::ThingStatusInfoEvent
  # rubocop:enable Style/ClassAndModuleChildren

  alias uid get_thing_uid
  alias status status_info
end
