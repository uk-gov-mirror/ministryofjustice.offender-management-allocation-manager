require 'rails_helper'

feature 'feedback' do
  it 'provides a link to the feedback form', vcr: { cassette_name: 'prison_api/feedback_link' } do
    signin_spo_user

    visit '/'

    feedback_link = 'https://www.research.net/r/MM8TNLW'

    footer = page.find(:css, '.govuk-footer')
    within footer do
      expect(page).to have_link('Feedback', href: feedback_link)
    end
  end
end
