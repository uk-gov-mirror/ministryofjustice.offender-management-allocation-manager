require 'rails_helper'

describe Nomis::Custody::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  around do |ex|
    travel_to Date.new(2018, 11, 12, 16) do
      ex.run
    end
  end

  it "gets staff details",
    vcr: { cassette_name: :get_nomis_staff_details } do
    username = 'PK000223'

    response = described_class.fetch_nomis_staff_details(username)

    expect(response).to be_kind_of(Nomis::StaffDetails)
    expect(response.active_nomis_caseload).to eq('LEI')
  end

  it 'gets prisoner information for a particular prison',
    vcr: { cassette_name: :get_prisoners } do
    prison = 'LEI'

    response = described_class.get_offenders(prison)

    expect(response.count).to eq(10)
    expect(response.first).to be_kind_of(Nomis::OffenderDetails)
  end

  # TODO: this end point returns an array. Find out how to handle.
  xit 'gets release details for a prisoner',
    vcr: { cassette_name: :get_release_details } do
      prisoner_id = '1317074'

      response = described_class.get_release_details(prisoner_id)

      expect(response).to be_kind_of(Nomis::ReleaseDetails)
    end
end
