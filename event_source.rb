#!/usr/bin/env ruby
require 'securerandom'

Event = Struct.new(:aggregate_uuid, :type, :payload)

EVENTS = []

module EventStore
  extend self

  def sink(events)
    EVENTS.concat(events)
  end

  def events_for_aggregate(aggregate_uuid)
    EVENTS.select { |event| event.aggregate_uuid == aggregate_uuid }
  end
end

module Account
  OutOfMoneyError = Class.new(StandardError)
  Aggregate = Struct.new(:uuid, :balance)
  Command = Struct.new(:amount)

  module Repository
    def self.load(aggregate_uuid)
      EventStore.events_for_aggregate(aggregate_uuid)
        .reduce(Aggregate.new(aggregate_uuid, 0)) do |account, event|

        case event.type
        when :deposit
          amount = event.payload.fetch(:amount)
          new_balance = account.balance + amount
          Aggregate.new(aggregate_uuid, new_balance)
        when :withdraw
          amount = event.payload.fetch(:amount)
          new_balance = account.balance - amount
          Aggregate.new(aggregate_uuid, new_balance)
        else
          account
        end
      end
    end
  end

  module CommandHandler
    extend self

    def deposit_money(account, command)
      deposit_amount = command.amount

      [Event.new(account.uuid, :deposit, {amount: deposit_amount})]
    end

    def withdraw_money(account, command)
      withdraw_amount = command.amount

      if account.balance < withdraw_amount
        raise OutOfMoneyError
      end

      [Event.new(account.uuid, :withdraw, {amount: withdraw_amount})]
    end
  end

  module API
    extend self

    def deposit_money(account_uuid, deposit_amount)
      command = Command.new(deposit_amount)
      account = Repository.load(account_uuid)
      events = CommandHandler.deposit_money(account, command)
      EventStore.sink(events)
    end

    def withdraw_money(account_uuid, withdraw_amount)
      command = Command.new(withdraw_amount)
      account = Repository.load(account_uuid)
      events = CommandHandler.withdraw_money(account, command)
      EventStore.sink(events)
    end
  end
end

account_uuid = SecureRandom.uuid

Account::API.deposit_money(account_uuid, 100)
Account::API.withdraw_money(account_uuid, 50)
Account::API.deposit_money(account_uuid, 25)

puts Account::Repository.load(account_uuid)
