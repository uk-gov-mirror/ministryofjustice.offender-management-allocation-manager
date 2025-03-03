require 'rails_helper'

describe HmppsApi::PrisonApi::MovementApi do
  describe 'Movements for date' do
    it 'can get movements on a specific date',
       vcr: { cassette_name: 'prison_api/movement_api_on_date' } do
      movements = described_class.movements_on_date(Date.iso8601('2019-02-20'))

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(2)
      expect(movements.first).to be_kind_of(HmppsApi::Movement)
    end
  end

  describe 'Movements for single offenders' do
    it 'can get movements for a specific_offender',
       vcr: { cassette_name: 'prison_api/movement_api_for_offender' } do
      movements = described_class.movements_for('A5019DY')

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(2)
      expect(movements.first).to be_kind_of(HmppsApi::Movement)
    end

    it 'sort movements (oldest first) for a specific_offender' do
      allow_any_instance_of(HmppsApi::Client).to receive(:post).and_return([
        attributes_for(:movement, offenderNo: '2', movementDate: '2017-03-09').stringify_keys,
        attributes_for(:movement, offenderNo: '1', movementDate: '2015-01-01').stringify_keys
      ])

      movements = described_class.movements_for('A5019DY')

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(2)
      expect(movements.first.offender_no).to eq('1')
    end

    it 'can return multiple movements for a specific offender',
       vcr: { cassette_name: 'prison_api/movement_api_multiple_movements' } do
      movements = described_class.movements_for('G1670VU')

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(5)
      expect(movements.first).to be_kind_of(HmppsApi::Movement)
    end
  end
end
