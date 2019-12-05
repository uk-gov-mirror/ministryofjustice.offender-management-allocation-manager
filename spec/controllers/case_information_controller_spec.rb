require 'rails_helper'

RSpec.describe CaseInformationController, type: :controller do
  before do
    stub_sso_data(prison)
  end

  let(:prison) { 'WEI' }

  let(:nomis_offender_id) { 'B44455' }

  let(:params) do
    { prison_id: prison }
  end

  context "when creating a prisoner's case information" do
    it 'redirects to summary pending path when offender is English or Welsh' do
      case_information_params = {
        case_information: {
          nomis_offender_id: nomis_offender_id,
          tier: 'B',
          case_allocation: 'NPS',
          welsh_offender: 'No',
          last_known_address: 'No',
          probation_service: 'England',
          local_divisional_unit_id: create(:local_divisional_unit).id
        }
      }

      post :create, params: params.merge(case_information_params)
      expect(response).to redirect_to prison_summary_pending_path(prison, sort: params[:sort], page: params[:page])
    end

    it 'redirects to summary pending path when offender is Scottish or Northern Irish' do
      case_information_params = {
        case_information: {
          nomis_offender_id: nomis_offender_id,
          last_known_address: 'Yes',
          probation_service: 'Northern Ireland'
        }
      }

      post :create, params: params.merge(case_information_params)
      expect(response).to redirect_to prison_summary_pending_path(prison, sort: params[:sort], page: params[:page])
    end
  end
end
