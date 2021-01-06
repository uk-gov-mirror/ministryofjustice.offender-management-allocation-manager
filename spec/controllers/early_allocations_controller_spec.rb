# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocationsController, :allocation, type: :controller do
  # any date less than 3 months in the past
  let(:valid_date) { Time.zone.today - 2.months }
  let(:s1_boolean_param_names) { [:convicted_under_terrorisom_act_2000, :high_profile, :serious_crime_prevention_order, :mappa_level_3, :cppc_case] }
  let(:s1_boolean_params) { s1_boolean_param_names.index_with { 'false' } }

  let(:prison) { build(:prison).code }
  let(:first_pom) { build(:pom) }
  let(:nomis_staff_id) { first_pom.staffId }

  let(:poms) {
    [
      first_pom,
      build(:pom)
    ]
  }

  let(:offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, conditionalReleaseDate: release_date)) }

  let(:nomis_offender_id) { offender.fetch(:offenderNo) }

  before do
    stub_signed_in_pom(prison, first_pom.staffId)
    stub_pom(first_pom)

    stub_offender(offender)
    stub_poms(prison, poms)
    stub_offenders_for_prison(prison, [offender])
    create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id)
  end

  context 'with some assessments' do
    before do
      create(:case_information, nomis_offender_id: nomis_offender_id, early_allocations: build_list(:early_allocation, 5))
    end

    let(:early_allocation) { assigns(:early_assignment) }

    describe '#show' do
      let(:release_date) { Time.zone.today + 17.months }

      it 'shows the most recent' do
        get :show, params: { prison_id: prison, prisoner_id: nomis_offender_id }, format: :pdf
        expect(early_allocation).to eq(CaseInformation.last.early_allocations.last)
      end

      it 'shows most recent html' do
        get :show, params: { prison_id: prison, prisoner_id: nomis_offender_id }, format: :html
        expect(early_allocation).to eq(CaseInformation.last.early_allocations.last)
      end
    end

    describe '#update' do
      let(:release_date) { Time.zone.today + 17.months }

      it 'updates the updated_by_ fields' do
        put :update, params: { prison_id: prison, prisoner_id: nomis_offender_id }
        expect(early_allocation.updated_by_firstname).to eq(first_pom.firstName)
        expect(early_allocation.updated_by_lastname).to eq(first_pom.lastName)
      end
    end
  end

  describe '#new' do
    let(:release_date) { Time.zone.today + 17.months }

    context 'with no ldu email address' do
      let(:ldu) { create(:local_divisional_unit, email_address: nil) }
      let(:team) { create(:team, local_divisional_unit: ldu) }

      before do
        create(:case_information, nomis_offender_id: nomis_offender_id, team: team)
      end

      it 'goes to the dead end' do
        get :new, params: { prison_id: prison,
                            prisoner_id: nomis_offender_id }

        assert_template 'dead_end'
      end
    end
  end

  describe '#create' do
    before do
      create(:case_information, nomis_offender_id: nomis_offender_id)
    end

    context 'when stage 1' do
      let(:stage1_params) {
        { "oasys_risk_assessment_date(3i)" => valid_date.day,
          "oasys_risk_assessment_date(2i)" => valid_date.month,
          "oasys_risk_assessment_date(1i)" => valid_date.year
        }.merge(s1_boolean_params)
      }
      let(:early_allocation) { EarlyAllocation.last }

      context 'when > 18 months from release' do
        let(:release_date) { Time.zone.today + 19.months }

        it 'stores false in created_within_referral_window' do
          post :create, params: { prison_id: prison,
                                  prisoner_id: nomis_offender_id,
                                  early_allocation: stage1_params.merge(high_profile: true) }
          assert_template('eligible')
          expect(early_allocation.created_within_referral_window).to eq(false)
        end
      end

      context 'when < 18 months from release' do
        let(:release_date) { Time.zone.today + 17.months }

        context 'when any one boolean true' do
          scenario 'declares assessment complete and eligible' do
            s1_boolean_param_names.each do |field|
              expect {
                post :create, params: { prison_id: prison,
                                        prisoner_id: nomis_offender_id,
                                        early_allocation: stage1_params.merge(field => true) }
              }.to change(EmailHistory, :count).by(1)
              assert_template('eligible')

              expect(early_allocation.prison).to eq(prison)
              expect(early_allocation.created_by_firstname).to eq(first_pom.firstName)
              expect(early_allocation.created_by_lastname).to eq(first_pom.lastName)
              expect(early_allocation.created_within_referral_window).to eq(true)
            end
          end
        end

        context 'when no booleans true' do
          render_views
          it 'renders the second screen of questions' do
            post :create, params: { prison_id: prison,
                                    prisoner_id: nomis_offender_id,
                                    early_allocation: stage1_params }
            assert_template('stage2')
            expect(response.body).to include('Extremism separation centres')
          end
        end
      end
    end

    context 'when stage 2' do
      let(:release_date) { Time.zone.today + 17.months }

      let(:s2_boolean_param_names) {
        [:due_for_release_in_less_than_24months,
         :high_risk_of_serious_harm,
         :mappa_level_2,
         :pathfinder_process,
         :other_reason]
      }

      let(:s2_boolean_params) { s2_boolean_param_names.index_with { |_p| 'false' }.to_h }

      it 'is ineligible if <24 months is false but extremism_separation is true' do
        post :create, params: {
          prison_id: prison,
          prisoner_id: nomis_offender_id,
          early_allocation: {
            oasys_risk_assessment_date: valid_date,
            extremism_separation: true,
            stage2_validation: true
          }.merge(s1_boolean_params).merge(s2_boolean_params)
        }

        assert_template 'ineligible'
      end
    end
  end
end
