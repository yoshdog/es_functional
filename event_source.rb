#!/usr/bin/env ruby

Event = Struct.new(:type, :payload)
events = [
  Event.new(:deposit, {amount: 100}),
  Event.new(:deposit, {amount: 200}),
  Event.new(:poop, {}),
  Event.new(:withdraw, {amount: 50}),
]

def transaction(state:, event:)
  case event.type
  when :deposit
    amount = event.payload.fetch(:amount)
    return state + amount
  when :withdraw
    amount = event.payload.fetch(:amount)
    return state - amount
  else
    return state
  end
end

current_balance = events.reduce(0) do |balance, event|
  transaction(state: balance, event: event)
end

puts current_balance
