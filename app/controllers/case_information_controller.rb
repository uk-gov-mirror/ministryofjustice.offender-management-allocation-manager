# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_case_info, only: [:edit, :show]
  before_action :set_prisoner_from_url, only: [:new, :edit, :edit_prd, :update_prd, :show]

  def new
    @case_info = CaseInformation.new(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      case_allocation: case_information_params[:case_allocation],
      probation_service: case_information_params[:probation_service],
      last_known_location: case_information_params[:last_known_location],
      team_id: team_identifier,
      manual_entry: true
    )

    params[:stage] == 'last_location' ? handle_stage1 : handle_stage2

    if @case_info.valid?
      @case_info.save
      send_email
      redirect_to prison_summary_pending_path(active_prison_id, sort: params[:sort], page: params[:page])
    end
  end

  def edit
    @case_info.last_known_location = if @case_info.probation_service == 'England'
                                       'No'
                                     else
                                       'Yes'
                                     end
    @team_name = Team.find_by(id: @case_info.team_id)&.name
  end

  def update
    @case_info = CaseInformation.find_by(nomis_offender_id: case_information_params[:nomis_offender_id])
    @prisoner = prisoner(case_information_params[:nomis_offender_id])

    # we only send email if the ldu is different from previous
    if case_information_updated?
      if CaseInformationService.ldu_changed?(@case_info.saved_change_to_team_id)
        send_email
      end
      redirect_to new_prison_allocation_path(active_prison_id, @case_info.nomis_offender_id)
    else
      render :edit
    end
  end

  # Just edit the parole_review_date field
  def edit_prd
    @case_info = ParoleReviewDateForm.new nomis_offender_id: nomis_offender_id_from_url
  end

  def update_prd
    @case_info = ParoleReviewDateForm.new nomis_offender_id: nomis_offender_id_from_url
    if @case_info.update(parole_review_date_params)
      redirect_to new_prison_allocation_path(active_prison_id, @case_info.nomis_offender_id)
    else
      render 'edit_prd'
    end
  end

  def show
    @delius_data = DeliusData.where(noms_no: nomis_offender_id_from_url)

    @delius_errors = if @delius_data.empty?
                       [DeliusImportError.new(
                         nomis_offender_id: nomis_offender_id_from_url,
                         error_type: DeliusImportError::MISSING_DELIUS_RECORD
                       )]
                     else
                       DeliusImportError.where(
                         nomis_offender_id: nomis_offender_id_from_url
                       )
                     end
    last_delius = DeliusData.order(:updated_at).last
    @next_update_date = if last_delius.present?
                          last_delius.updated_at + 1.day
                        else
                          Date.tomorrow
                        end
  end

private

  def set_prisoner_from_url
    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  def set_case_info
    @case_info = CaseInformation.find_by(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def prisoner(nomis_id)
    @prisoner ||= OffenderService.get_offender(nomis_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def stage1_errors
    if case_information_params[:last_known_location].nil?
      @case_info.errors.messages.reject! do |f, _m|
        f != :probation_service && f != :last_known_location
      end
      display_address_page
    elsif case_information_params[:last_known_location] == 'Yes' && case_information_params[:probation_service].nil?
      @case_info.errors.messages.select! do |f, _m|
        f == :probation_service
      end
      display_address_page
    end
  end

  def display_address_page
    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    render :new
  end

  def handle_stage1
    if @case_info.scottish_or_ni?
      @case_info.save_scottish_or_ni
    elsif @case_info.english_or_welsh?
      @case_info.probation_service = 'England' if @case_info.last_known_location == 'No'
      @prisoner = prisoner(case_information_params[:nomis_offender_id])
      @case_info.errors.clear
      render :missing_info
    else
      stage1_errors
    end
  end

  def handle_stage2
    @case_info.probation_service = 'England' if @case_info.english?

    unless @case_info.stage2_filled?
      @prisoner = prisoner(case_information_params[:nomis_offender_id])
      @case_info.errors.messages.reject! do |f, _m|
        [:probation_service].include?(f)
      end
      render :missing_info
    end
  end

  def case_information_updated?
    if ['Scotland', 'Northern Ireland'].include?(case_information_params[:probation_service]) &&
      case_information_params[:last_known_location] == 'Yes'
      @case_info.update(probation_service: case_information_params[:probation_service], tier: 'N/A',
                        case_allocation: 'N/A', team: nil, manual_entry: true)
    else
      probation = if case_information_params[:last_known_location] == 'No'
                    'England'
                  else
                    case_information_params[:probation_service]
                  end

      @case_info.update(probation_service: probation, tier: case_information_params[:tier],
                        case_allocation: case_information_params[:case_allocation],
                        team_id: team_identifier,  manual_entry: true)
    end
  end

  def team_identifier
    Team.find_by(name: params['input-autocomplete'])&.id
  end

  def send_email
    return unless @case_info.probation_service == 'England' || @case_info.probation_service == 'Wales'

    prepare_email
  end

  def prepare_email
    spo = Nomis::Elite2::UserApi.user_details(current_user).email_address.try(:first)
    ldu = @case_info.team.try(:local_divisional_unit)
    emails = [ldu.try(:email_address), spo]
    delius_error = DeliusImportError.where(nomis_offender_id: @case_info.nomis_offender_id).first
    message = helpers.delius_email_message(delius_error&.error_type)
    notice_to_spo = helpers.spo_message(ldu)

    emails.each do |email|
      next if email.blank?

      notice_info = send_notice(email, spo, notice_to_spo)
      CaseAllocationEmailJob.perform_later(email: email,
                                           ldu: ldu,
                                           nomis_offender_id: @case_info.nomis_offender_id,
                                           message: message,
                                           notice: notice_info)
    end

    prisoner = prisoner(@case_info.nomis_offender_id)
    flash[:notice] = helpers.flash_notice_text(error_type: delius_error&.error_type, prisoner: prisoner,
                                               email_count: emails.compact.count)
    flash[:alert] = helpers.flash_alert_text(spo: spo, ldu: ldu, team_name: @case_info.team.name)
  end

  def send_notice(email, spo_email, notice)
    email == spo_email ? notice : ''
  end

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation,
             :parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy,
             :probation_service, :last_known_location, :team_id)
  end

  def parole_review_date_params
    params.require(:parole_review_date_form).
      permit(:parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end
end
