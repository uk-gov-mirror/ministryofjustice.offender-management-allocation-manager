# frozen_string_literal: true

class Bucket
  include Enumerable

  def initialize(sortable_fields)
    @items = []
    @valid_sort_fields = sortable_fields
  end

  def each
    @items.each { |item| yield item }
  end

  def <<(item)
    @items << item
  end

  def sort_bucket!(field, direction = :asc)
    return unless @valid_sort_fields.include?(field)

    @items.sort_by!(&field)

    @items.reverse! if direction == :desc
  end
end
