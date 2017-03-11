#/usr/bin/env ruby

Event = Struct.new(:type, :payload)
events = [
  Event.new(:increment, {}),
  Event.new(:increment, {}),
  Event.new(:poop, {}),
  Event.new(:decrement, {}),
]

def counter(state:, event:)
  case event.type
  when :increment
    return state + 1
  when :decrement
    return state - 1
  else
    return state
  end
end

final_count = events.reduce(0) do |count, event|
  counter(state: count, event: event)
end

puts final_count
