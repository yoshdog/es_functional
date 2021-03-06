#!/usr/bin/env ruby
require 'securerandom'

Event = Struct.new(:aggregate_uuid, :type, :payload)

module EventStore
  extend self

  EVENTS = []

  def sink(events)
    EVENTS.concat(events)
  end

  def events_for_aggregate(aggregate_uuid)
    EVENTS.select { |event| event.aggregate_uuid == aggregate_uuid }
  end
end

module Account
  OutOfMoneyError = Class.new(StandardError)
  State = Struct.new(:uuid, :balance)
  Command = Struct.new(:amount)

  # These are functions which generate events based on the the current state
  # and a command
  # fn(state, command) -> events
  def self.deposit_money(state, command)
    deposit_amount = command.amount

    [Event.new(state.uuid, :deposit, {amount: deposit_amount})]
  end

  def self.withdraw_money(state, command)
    withdraw_amount = command.amount

    if state.balance < withdraw_amount
      raise OutOfMoneyError
    end

    [Event.new(state.uuid, :withdraw, {amount: withdraw_amount})]
  end

  module Repository
    def self.load(aggregate_uuid)
      # Fold left. ie: reduce
      EventStore.events_for_aggregate(aggregate_uuid)
        .reduce(State.new(aggregate_uuid, 0)) do |state, event|

        # Pattern match
        case event.type

        # functions which change the state given an event.
        # fn(state, event) -> state
        when :deposit
          amount = event.payload.fetch(:amount)
          new_balance = state.balance + amount
          State.new(aggregate_uuid, new_balance)
        when :withdraw
          amount = event.payload.fetch(:amount)
          new_balance = state.balance - amount
          State.new(aggregate_uuid, new_balance)
        else
          state
        end
      end
    end
  end

  # Our public interface which Glues everything together.
  # Contains both Command and Query methods but can be seperated.
  module API
    extend self

    def deposit_money(account_uuid, deposit_amount)
      command = Command.new(deposit_amount)
      account = Repository.load(account_uuid)
      events = ::Account.deposit_money(account, command)
      EventStore.sink(events)
    end

    def withdraw_money(account_uuid, withdraw_amount)
      command = Command.new(withdraw_amount)
      account = Repository.load(account_uuid)
      events = ::Account.withdraw_money(account, command)
      EventStore.sink(events)
    end

    def get_current_balance(account_uuid)
      # Will need to build a projection so we don't need to
      # read the entire stream to do a lookup.
      account = Repository.load(account_uuid)
      """
      Balance for account #{account_uuid}
      ---------------------------------------------------------

      $ #{account.balance}
      """
    end
  end
end

account_uuid = SecureRandom.uuid

Account::API.deposit_money(account_uuid, 100)
Account::API.withdraw_money(account_uuid, 50)
Account::API.deposit_money(account_uuid, 25)

puts Account::API.get_current_balance(account_uuid)
