require 'rails_helper'

RSpec.describe Override, type: :model do
  it {
    expect(subject).to validate_presence_of(:nomis_offender_id).with_message('must be provided')
  }

  it {
    expect(subject).to validate_presence_of(:nomis_staff_id).with_message('must be provided')
  }

  it {
    expect(subject).to validate_presence_of(:override_reasons).with_message('must be provided')
  }

  it {
    o = described_class.create(nomis_offender_id: 'A', nomis_staff_id: 1, override_reasons: ['other'])
    expect(o.valid?).to be false
    expect(o.errors[:more_detail].count).to eq(1)
    expect(o.errors[:more_detail].first).to eq('must be provided when Other is selected')
  }

  it {
    o = described_class.create(nomis_offender_id: 'A', nomis_staff_id: 1, override_reasons: ['cats'])
    expect(o.valid?).to be true
    expect(o.errors[:more_detail].count).to eq(0)
  }
end
