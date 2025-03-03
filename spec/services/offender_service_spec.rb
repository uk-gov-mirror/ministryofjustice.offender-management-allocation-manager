require 'rails_helper'

describe OffenderService, type: :feature do
  describe '#get_offender' do
    it "gets a single offender", vcr: { cassette_name: 'prison_api/offender_service_single_offender_spec' } do
      nomis_offender_id = 'G4273GI'

      create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'C', case_allocation: 'CRC', probation_service: 'Wales')
      offender = described_class.get_offender(nomis_offender_id)

      expect(offender).to be_kind_of(HmppsApi::OffenderBase)
      expect(offender.tier).to eq 'C'
      expect(offender.sentence.conditional_release_date).to eq(Date.new(2020, 3, 16))
      expect(offender.main_offence).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
      expect(offender.case_allocation).to eq 'CRC'
    end

    it "returns nil if offender record not found", vcr: { cassette_name: 'prison_api/offender_service_single_offender_not_found_spec' } do
      nomis_offender_id = 'AAA121212CV4G4GGVV'

      offender = described_class.get_offender(nomis_offender_id)
      expect(offender).to be_nil
    end

    context 'when offender is not in prison' do
      let(:offender) { build(:nomis_offender, currentlyInPrison: 'N', agencyId: 'OUT') }

      before do
        stub_auth_token
        stub_offender(offender)
      end

      it 'returns the offender' do
        expect(described_class.get_offender(offender.fetch(:offenderNo))).not_to be_nil
      end
    end

    context 'when offender is in an unknown prison' do
      # MHI - Morton Hall immigration centre
      let(:offender) { build(:nomis_offender, agencyId: 'MHI') }
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        stub_auth_token
        stub_offender(offender)
        test_strategy.switch!(:womens_estate, true)
      end

      after do
        test_strategy.switch!(:womens_estate, false)
      end

      it 'returns the offender' do
        expect(described_class.get_offender(offender.fetch(:offenderNo))).not_to be_nil
      end
    end
  end

  describe '#get_community_data' do
    # This offender has been set up in nDelius test especially for this test
    let(:nomis_offender_id) { 'G0239GU' }

    # This test can only be run inside the VPN as nDelius test isn't globally accessible
    context 'when hitting API', :vpn_only, vcr: { cassette_name: 'delius/get_community_data' } do
      it 'gets some data' do
        expect(described_class.get_community_data(nomis_offender_id)).
            to eq(crn: "X362207",
                  ldu_code: "N07NPSA",
                  mappa_levels: [2],
                  noms_no: nomis_offender_id,
                  offender_manager: nil,
                  service_provider: "NPS",
                  team_code: "N07UAT",
                  tier: "A-2")
      end
    end

    context 'with stubbing' do
      before do
        stub_auth_token
      end

      context 'without MAPPA data' do
        describe '#service_provider' do
          context 'when NPS' do
            before do
              stub_community_offender(nomis_offender_id,
                                      build(:community_data,
                                            offenderManagers: [
                                                build(:community_offender_manager, probationArea: { nps: true })
                                            ]))
            end

            it 'gets NPS' do
              expect(described_class.get_community_data(nomis_offender_id).fetch(:service_provider)).to eq('NPS')
            end
          end

          context 'when CRC' do
            before do
              stub_community_offender(nomis_offender_id,
                                      build(:community_data,
                                            offenderManagers: [
                                                build(:community_offender_manager, probationArea: { nps: false })
                                            ]))
            end

            it 'gets CRC' do
              expect(described_class.get_community_data(nomis_offender_id).fetch(:service_provider)).to eq('CRC')
            end
          end
        end

        context 'with a single allocated COM' do
          before do
            stub_community_offender(nomis_offender_id, build(:community_data,
                                                             offenderManagers: [{ probationArea: { nps: true }, active: true, staff: { unallocated: false, surname: 'Jones', forenames: 'Ruth Mary' } }]))
          end

          it 'gets the surname and forenames' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:offender_manager))
                .to eq('Jones, Ruth Mary')
          end
        end

        context 'with multiple allocated COMs' do
          before do
            stub_community_offender(nomis_offender_id, build(:community_data,
                                                             offenderManagers: [
                                                                 { active: false, staff: { unallocated: false, surname: 'Jones', forenames: 'Ruth Mary' } },
                                                                 { active: true, staff: { unallocated: false, surname: 'Smith', forenames: 'Mel Griff' } },
                                                                 { active: false, staff: { unallocated: false, surname: 'Rabbit', forenames: 'Richard Oliver' } },
                                                             ]))
          end

          it 'gets the surname and forenames' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:offender_manager)).to eq('Smith, Mel Griff')
          end
        end
      end

      context 'with MAPPA data' do
        before do
          stub_community_offender(nomis_offender_id,
                                  build(:community_data,
                                        currentTier: 'A',
                                        otherIds: { crn: 'X5657657' },
                                        offenderManagers: [
                                            {
                                                team: { code: 'N07GHGF', localDeliveryUnit: { code: 'LDU123' } },
                                                probationArea: { nps: true },
                                                active: true,
                                                staff: { unallocated: true } }
                                        ]), registrations)
        end

        context 'with an inactive registration' do
          let(:registrations) { [build(:community_registration, active: false)] }

          it 'gets some data' do
            expect(described_class.get_community_data(nomis_offender_id))
                .to eq(noms_no: nomis_offender_id, tier: 'A', crn: 'X5657657', offender_manager: nil, service_provider: 'NPS', mappa_levels: [], team_code: 'N07GHGF', ldu_code: 'LDU123')
          end
        end

        context 'with an active non-MAPPA registration' do
          let(:registrations) { [build(:community_registration)] }

          it 'gets empty mappa levels' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:mappa_levels))
                .to eq([])
          end
        end

        context 'with an active MAPPA registration' do
          let(:registrations) { [build(:community_registration, :mappa_2)] }

          it 'gets mappa_levels' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:mappa_levels))
                .to eq([2])
          end
        end
      end
    end
  end
end
