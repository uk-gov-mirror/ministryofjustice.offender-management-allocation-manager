# frozen_string_literal: true

class MovementService
  ADMISSION_MOVEMENT_CODE = 'IN'
  RELEASE_MOVEMENT_CODE = 'OUT'
  IMMIGRATION_MOVEMENT_CODES = %w[IMM MHI].freeze

  def self.movements_on(date)
    HmppsApi::PrisonApi::MovementApi.movements_on_date(date)
  end

  def self.process_movement(movement)
    if movement.movement_type == HmppsApi::MovementType::RELEASE
      return process_release(movement)
    end

    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    if [HmppsApi::MovementType::ADMISSION,
        HmppsApi::MovementType::TRANSFER].include?(movement.movement_type)

      return process_transfer(movement)
    end

    Rails.logger.info("[MOVEMENT] Ignoring #{movement.movement_type}")

    false
  end

private

  def self.process_transfer(transfer)
    return false unless transfer.in?

    Rails.logger.info("[MOVEMENT] Processing transfer for #{transfer.offender_no}")

    # Remove the case information and deallocate offender
    # when the movement is from immigration or a detention centre
    # and is not going back to a prison OR
    # when the movement is from a prison to an immigration or detention centre
    if ((IMMIGRATION_MOVEMENT_CODES.include? transfer.from_agency) && !transfer.to_prison?) ||
    ((IMMIGRATION_MOVEMENT_CODES.include? transfer.to_agency) && transfer.from_prison?)
      release_offender(transfer.offender_no)

      return true
    end

    # Bail if this is a new admission to prison
    return false unless transfer.from_prison? && transfer.to_prison?

    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    if Allocation.where(
      nomis_offender_id: transfer.offender_no,
      prison: transfer.to_agency
    ).count > 0

      Rails.logger.info("[MOVEMENT] Offender #{transfer.offender_no} was transferred but \
        an allocation at #{transfer.to_agency} already exists")

      return false
    end

    Rails.logger.info("[MOVEMENT] De-allocating #{transfer.offender_no}")

    alloc = Allocation.find_by(nomis_offender_id: transfer.offender_no)

    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    # There are special rules for responsibility when offenders
    # move to open prisons so we will trigger this job to send
    # an email to the LDU
    # Bail if this is a new admission to prison
    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    # When an offender is released, we can no longer rely on their
    # case information (in case they come back one day), and we
    # should de-activate any current allocations.
    alloc.dealloate_offender_after_transfer if alloc&.active?

    if PrisonService.open_prison?(transfer.to_agency)
      # There are special rules for responsibility when offenders
      # move to open prisons so we will trigger this job to send
      # an email to the LDU
      OpenPrisonTransferJob.perform_later(transfer.to_json)
    end
    true
  end

  # When an offender is released, we can no longer rely on their
  # case information (in case they come back one day), and we
  # should de-activate any current allocations.
  def self.process_release(release)
    return false unless release.to_agency == RELEASE_MOVEMENT_CODE

    if release.from_agency == IMMIGRATION_MOVEMENT_CODES.first || release.from_agency == IMMIGRATION_MOVEMENT_CODES.last
      release_offender(release.offender_no)

      return true
    end

    return false unless release.from_prison?

    release_offender(release.offender_no)
    true
  end

  def self.release_offender(offender_no)
    Rails.logger.info("[MOVEMENT] Processing release for #{offender_no}")

    CaseInformation.where(nomis_offender_id: offender_no).destroy_all
    alloc = Allocation.find_by(nomis_offender_id: offender_no)
    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    # There are special rules for responsibility when offenders
    # move to open prisons so we will trigger this job to send
    # an email to the LDU
    # Bail if this is a new admission to prison
    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    # When an offender is released, we can no longer rely on their
    # case information (in case they come back one day), and we
    # should de-activate any current allocations.
    alloc.deallocate_offender_after_release if alloc
  end
end
