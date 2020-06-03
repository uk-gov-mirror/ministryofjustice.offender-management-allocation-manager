FactoryBot.define do
  factory :offender, class: 'Nomis::Offender' do
    inprisonment_status do 'SENT03' end
    sentence do
      Nomis::SentenceDetail.new automatic_release_date: Time.zone.today + 1.year,
                                sentence_start_date: Time.zone.today
    end
    prison_id { 'LEI' }
    case_allocation { 'NPS' }
    mappa_level { 0 }
  end
end
