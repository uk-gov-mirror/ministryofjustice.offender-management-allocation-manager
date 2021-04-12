# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessDeliusDataJob, :disable_push_to_delius, type: :job do
  let(:nomis_offender_id) { 'G4281GV' }
  let(:remand_nomis_offender_id) { 'G3716UD' }
  let(:ldu) {  create(:local_divisional_unit) }
  let(:team) { create(:team, local_divisional_unit: ldu) }

  before do
    stub_auth_token
  end

  context 'with auto_delius_import enabled' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }
    let(:case_info) { CaseInformation.last }

    before do
      test_strategy.switch!(:auto_delius_import, true)
    end

    after do
      test_strategy.switch!(:auto_delius_import, false)
    end


    context 'when on the happy path' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        stub_community_offender(nomis_offender_id, build(:community_data, offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      it 'creates case information' do
        expect {
          described_class.perform_now nomis_offender_id
        }.to change(CaseInformation, :count).by(1)

        expect(case_info.attributes.symbolize_keys.except(:created_at, :id, :updated_at, :parole_review_date, :welsh_offender))
            .to eq(case_allocation: "NPS", crn: "X362207", manual_entry: false, mappa_level: 0,
                   nomis_offender_id: "G4281GV",
                   probation_service: "England",
                   local_delivery_unit_id: nil,
                   team_id: team.id,
                   team_name: team.name,
                   com_name: "Jones, Ruth Mary",
                   tier: "A")
      end
    end

    context 'when processing a com name' do
      let(:offender_id) { 'A1111A' }

      before do
        stub_offender(build(:nomis_offender, offenderNo: offender_id))

        stub_community_offender(offender_id, build(:community_data, offenderManagers: [build(:community_offender_manager, staff: { unallocated: unallocated, forenames: 'Bob', surname: 'Smith' }, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      context 'with a normal COM name' do
        let(:com_name) { 'Smith, Bob' }
        let(:unallocated) { false }

        it 'shows com name' do
          expect {
            described_class.perform_now offender_id
          }.to change(CaseInformation, :count).by(1)

          expect(case_info.com_name).to eq(com_name)
        end
      end

      context 'with an unallocated com name' do
        let(:com_name) { 'Staff, Unallocated' }
        let(:unallocated) { true }

        it 'maps com_name to nil' do
          expect {
            described_class.perform_now offender_id
          }.to change(CaseInformation, :count).by(1)

          expect(case_info.com_name).to be_nil
        end
      end

      context 'with an inactive com name' do
        let(:com_name) { 'Staff, Inactive Staff(N07)' }
        let(:unallocated) { true }

        it 'maps com_name to nil' do
          expect {
            described_class.perform_now offender_id
          }.to change(CaseInformation, :count).by(1)

          expect(case_info.com_name).to be_nil
        end
      end
    end

    context 'when offender is not convicted' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: remand_nomis_offender_id, convictedStatus: 'Remand'))
        stub_community_offender(remand_nomis_offender_id, build(:community_data, offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      it 'does not store case information' do
        expect {
          described_class.perform_now remand_nomis_offender_id
        }.to change(CaseInformation, :count).by(0)
      end
    end

    context 'when tier contains extra characters' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        stub_community_offender(nomis_offender_id, build(:community_data, currentTier: 'B1', offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      it 'creates case information' do
        expect {
          described_class.perform_now nomis_offender_id
        }.to change(CaseInformation, :count).by(1)
        expect(case_info.tier).to eq('B')
      end
    end

    context 'when tier is invalid' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        stub_community_offender(nomis_offender_id, build(:community_data, currentTier: 'X', offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      it 'does not create case information' do
        expect {
          described_class.perform_now nomis_offender_id
        }.not_to change(CaseInformation, :count)
      end
    end

    describe '#probation_service' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        stub_community_offender(nomis_offender_id, build(:community_data, offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      context 'with an English LDU' do
        let(:ldu) { create(:local_divisional_unit, in_wales: false) }

        it 'maps to false' do
          described_class.perform_now(nomis_offender_id)
          expect(case_info.probation_service).to eq('England')
        end
      end

      context 'with an Welsh LDU' do
        let(:ldu) { create(:local_divisional_unit, in_wales: true) }

        it 'maps to true' do
          described_class.perform_now(nomis_offender_id)
          expect(case_info.probation_service).to eq('Wales')
        end
      end
    end

    describe '#local_delivery_unit' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        stub_community_offender(nomis_offender_id, build(:community_data, offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      context 'with an existing new shiny LDU' do
        before do
          create(:local_delivery_unit, code: ldu.code)
        end

        let(:local_delivery_unit) { LocalDeliveryUnit.last }

        it 'maps to the new one' do
          described_class.perform_now(nomis_offender_id)
          expect(case_info.local_delivery_unit).to eq local_delivery_unit
        end
      end
    end

    describe '#mappa' do
      before do
        stub_community_offender(nomis_offender_id, build(:community_data,
                                                         offenderManagers: [
                                                             build(:community_offender_manager,
                                                                   team: { code: team.code,
                                                                           localDeliveryUnit: { code: ldu.code } })
                                                         ]), registrations)
      end

      context 'without delius mappa' do
        before do
          stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        end

        let(:registrations) { [] }

        it 'creates case information with mappa level 0' do
          expect {
            described_class.perform_now nomis_offender_id
          }.to change(CaseInformation, :count).by(1)
          expect(case_info.mappa_level).to eq(0)
        end
      end

      context 'with delius mappa' do
        before do
          stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        end

        let(:registrations) { mappa_levels.map { |m| build(:community_registration, registerLevel: { code: "M#{m}" }) } }

        context 'with delius mappa data is 1' do
          let(:mappa_levels) { ['1'] }

          it 'creates case information with mappa level 1' do
            expect {
              described_class.perform_now nomis_offender_id
            }.to change(CaseInformation, :count).by(1)
            expect(case_info.mappa_level).to eq(1)
          end
        end

        context 'with delius mappa data is 1,2' do
          let(:mappa_levels) { ['1', '2'] }

          it 'creates case information with mappa level 2' do
            expect {
              described_class.perform_now nomis_offender_id
            }.to change(CaseInformation, :count).by(1)
            expect(case_info.mappa_level).to eq(2)
          end
        end

        context 'with delius mappa data is 1,Nominal' do
          let(:mappa_levels) { ['1', 'Nominal'] }

          it 'creates case information with mappa level 1' do
            expect {
              described_class.perform_now nomis_offender_id
            }.to change(CaseInformation, :count).by(1)
            expect(case_info.mappa_level).to eq(1)
          end
        end
      end
    end

    context 'when case information already present' do
      before do
        stub_offender(build(:nomis_offender, offenderNo: nomis_offender_id))
        stub_community_offender(nomis_offender_id, build(:community_data, currentTier: 'C', offenderManagers: [build(:community_offender_manager, team: { code: team.code, localDeliveryUnit: { code: ldu.code } })]))
      end

      let!(:c1) { create(:case_information, tier: 'B', nomis_offender_id: nomis_offender_id) }

      it 'does not creates case information' do
        expect {
          described_class.perform_now nomis_offender_id
        }.not_to change(CaseInformation, :count)
        expect(c1.reload.tier).to eq('C')
      end
    end
  end

  describe 'pushing handover dates into nDelius' do
    let(:offender) { build(:nomis_offender) }
    let(:offender_no) { offender.fetch(:offenderNo) }
    let(:crn) { 'X89264GC' }

    before do
      stub_community_offender(offender_no, build(:community_data,
                                                 currentTier: 'C',
                                                 otherIds: { crn: crn },
                                                 offenderManagers: [
                                                   build(:community_offender_manager,
                                                         team: {
                                                           code: team.code,
                                                           localDeliveryUnit: { code: ldu.code }
                                                         })
                                                 ]))
      stub_offender(offender)
    end

    shared_examples 'recalculate handover dates' do
      it "recalculates the offender's handover dates, using the new Case Information data" do
        expect(CalculatedHandoverDate).to receive(:recalculate_for) do |received_offender|
          expect(received_offender).to be_an_instance_of(HmppsApi::Offender)

          expected_fields = {
            crn: crn,
            tier: 'C',
            case_allocation: 'NPS',
            welsh_offender: false,
            mappa_level: 0
          }

          received_fields = {
            crn: received_offender.crn,
            tier: received_offender.tier,
            case_allocation: received_offender.case_allocation,
            welsh_offender: received_offender.welsh_offender,
            mappa_level: received_offender.mappa_level
          }

          expect(received_fields).to eq(expected_fields)
        end
        described_class.perform_now offender_no
      end
    end

    context 'when creating a new Case Information record' do
      include_examples 'recalculate handover dates'
    end

    context 'when updating an existing Case Information record' do
      let!(:case_info) {
        create(:case_information, tier: 'B', nomis_offender_id: offender_no, crn: crn)
      }

      include_examples 'recalculate handover dates'

      it 'does not re-calculate if CaseInformation is unchanged' do
        described_class.perform_now offender_no
        expect(CalculatedHandoverDate).not_to receive(:recalculate_for)
        described_class.perform_now offender_no
      end
    end
  end
end
