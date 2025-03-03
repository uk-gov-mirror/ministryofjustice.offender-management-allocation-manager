require 'rails_helper'

RSpec.describe HistoryHelper do
  let(:current_allocation) {
    build_stubbed(
      :allocation,
      prison: 'LEI'
    )
  }

  let(:middle_allocation1) {
    build_stubbed(
      :allocation,
      prison: 'PVI'
    )
  }

  let(:middle_allocation2) {
    build_stubbed(
      :allocation,
      prison: 'PVI'
    )
  }

  let(:old_allocation) {
    build_stubbed(
      :allocation,
      primary_pom_allocated_at: DateTime.now.utc - 4.days,
      prison: 'LEI',
      event: Allocation::REALLOCATE_PRIMARY_POM,
      event_trigger: Allocation::USER
    )
  }

  let(:nil_allocation) {
    build_stubbed(
      :allocation,
      prison: nil
    )
  }

  context 'with 1, 2, 1' do
    it 'can group the allocations correctly' do
      list = AllocationList.new([current_allocation, middle_allocation1, middle_allocation2, old_allocation])

      expect(list.map { |prison, allocations| [prison, allocations.count] }).to eq [["LEI", 1], ["PVI", 2], ["LEI", 1]]
    end
  end

  context 'with nil prison at the start of the list' do
    it 'copes' do
      list = AllocationList.new([nil_allocation, current_allocation, middle_allocation1, middle_allocation2])

      expect(list.map { |prison, allocations| [prison, allocations.count] }).to eq [["LEI", 2], ["PVI", 2]]
    end
  end

  context 'with nil prison at end of list' do
    it 'sweeps item into current prison' do
      list = AllocationList.new([middle_allocation1, middle_allocation2, nil_allocation])

      expect(list.map { |prison, allocations| [prison, allocations.count] }).to eq [["PVI", 3]]
    end
  end
end
