require 'rails_helper'

RSpec.describe "summary/handover", type: :view do
  context 'when an SPO views the case handover page' do
    signin_spo_user
    assign( [build(:offender)])
    it 'displays a POM column' do

    end
  end
end