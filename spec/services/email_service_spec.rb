require 'rails_helper'

RSpec.describe EmailService do
  include ActiveJob::TestHelper

  let(:allocation) {
    Allocation.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.allocated_at_tier = 'A'
      a.prison = prison_code
    end
  }

  let(:reallocation) {
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_766
      a.nomis_offender_id = 'G2911GD'
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = Allocation::REALLOCATE_PRIMARY_POM
      a.event_trigger = Allocation::USER
    }
  }

  let(:original_allocation) {
    # The original allocation before the reallocation
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = Allocation::ALLOCATE_PRIMARY_POM
      a.event_trigger = Allocation::USER
    }
  }

  let(:coworking_allocation) do
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.secondary_pom_nomis_id = 485_926
      a.secondary_pom_name = "Pom, Moic"
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = Allocation::ALLOCATE_SECONDARY_POM
      a.event_trigger = Allocation::USER
    }
  end

  let(:coworking_deallocation) do
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.secondary_pom_nomis_id = nil
      a.secondary_pom_name = nil
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = Allocation::DEALLOCATE_SECONDARY_POM
      a.event_trigger = Allocation::USER
    }
  end

  let(:andrien) { build(:pom, staffId: 485_833) }
  let(:leigh) { build(:pom, staffId: 485_766) }
  let(:offender) { build(:nomis_offender, agencyId: prison_code, offenderNo: 'G2911GD') }
  let(:prison) { build(:prison) }
  let(:prison_code) { prison.code }
  let(:offender_name) { "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}" }

  before {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
    stub_auth_token
    create(:case_information, nomis_offender_id: 'G2911GD')
    stub_offender(offender)
    stub_poms(prison_code, [andrien, leigh])
  }

  context 'when queueing', :queueing do
    it "Can send an allocation email"  do
      expect {
        described_class.instance(allocation: allocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(1)
    end

    it "Can not crash when a pom has no email"  do
      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:fetch_email_addresses).and_return([])

      expect {
        described_class.instance(allocation: allocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(0)
    end

    it "Can send a reallocation email"  do
      allow(reallocation).to receive(:get_old_versions).and_return([original_allocation])

      expect {
        described_class.instance(allocation: reallocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(2)
    end

    it "Can send a co-working de-allocation email" do
      allow(original_allocation).to receive(:get_old_versions).and_return([coworking_allocation])

      expect {
        described_class.instance(allocation: coworking_deallocation,
                                 message: "",
                                 pom_nomis_id: coworking_deallocation.primary_pom_nomis_id
        ).send_cowork_deallocation_email(coworking_allocation.secondary_pom_name)
      }.to change(enqueued_jobs, :size).by(1)
    end

    it "Can not crash when primary pom has no email when deallocating a co-working pom" do
      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:fetch_email_addresses).and_return([])

      expect {
        described_class.instance(allocation: coworking_deallocation,
                                 message: "",
                                 pom_nomis_id: coworking_deallocation.primary_pom_nomis_id
        ).send_cowork_deallocation_email(coworking_allocation.secondary_pom_name)
      }.to change(enqueued_jobs, :size).by(0)
    end
  end

  context 'when offender has been released' do
    let(:staff_id) { '485833' }
    let!(:released_allocation) do
      create(:allocation,
             prison: prison_code,
             nomis_offender_id: original_allocation.nomis_offender_id,
             primary_pom_nomis_id: original_allocation.primary_pom_nomis_id).tap do |x|
        x.deallocate_offender_after_release
        x.reload
        x.update!(primary_pom_nomis_id: reallocation.primary_pom_nomis_id,
                  event: Allocation::REALLOCATE_PRIMARY_POM,
                  event_trigger: Allocation::USER)
        x.deallocate_offender_after_release
        x.reload
        x.update!(primary_pom_nomis_id: original_allocation.primary_pom_nomis_id,
                  event: Allocation::REALLOCATE_PRIMARY_POM,
                  event_trigger: Allocation::USER)
      end
    end

    it "Can send a reallocation email" do
      expect(PomMailer).to receive(:deallocation_email).with(
        previous_pom_name: leigh.first_name,
        responsibility: 'responsible',
        previous_pom_email: leigh.email_address,
        new_pom_name: "#{andrien.last_name}, #{andrien.first_name}",
        offender_name: offender_name,
        offender_no: "G2911GD",
        prison: prison.name,
        url: "http://localhost:3000/prisons/#{prison_code}/staff/#{staff_id}/caseload"
      ).and_return OpenStruct.new(deliver_later: true)

      expect(PomMailer).to receive(:new_allocation_email).with(
        pom_name: andrien.first_name,
        responsibility: 'responsible',
        pom_email: andrien.email_address,
        offender_name: offender_name,
        offender_no: "G2911GD",
        message: '',
        url: "http://localhost:3000/prisons/#{prison_code}/staff/#{staff_id}/caseload"
      ).and_return OpenStruct.new(deliver_later: true)

      described_class.
        instance(allocation: released_allocation, message: "", pom_nomis_id: released_allocation.primary_pom_nomis_id).
        send_email
    end
  end
end
