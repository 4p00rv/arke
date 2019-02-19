# encoding: UTF-8
# frozen_string_literal: true

require 'rbtree'
require_relative 'price_level'

module Arke
  class Orderbook
    UnsupportedEvent = Class.new(StandardError)

    def initialize(market)
      @market = market
      @orders = {}
      @orders_queue = EventMachine::Queue.new
      @book = {
        sell: ::RBTree.new,
        buy: ::RBTree.new
      }
      @callbacks = {
        stop: [],
        create: []
      }
    end

    def register(event, callback)
      raise UnsupportedEvent.new(event) unless @callbacks[event]

      @callbacks[event].push(callback)
    end

    def empty?
      @orders.empty?
    end

    def add(order)
      return if order.nil?

      @orders[order.id] = order
      @orders_queue.push(order)

      side = @book[order.side]
      side[order.price] ||= PriceLevel.new(order.price)
      side[order.price].add order

      @callbacks[:create].each { |c| c.call(order) }
    end

    def remove(id)
      order = @orders[id]
      return if order.nil?

      @book[order.side][order.price].remove(order)
      @orders.delete(id)

      @callbacks[:stop].each { |c| c.call(order) }
    end

    def find(id)
      @orders[id]
    end

    def dump
      @book
    end

    def orders_queue
      @orders_queue
    end
  end
end
