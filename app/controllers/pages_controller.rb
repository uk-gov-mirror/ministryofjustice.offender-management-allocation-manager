# frozen_string_literal: true

class PagesController < ApplicationController
  layout 'errors_and_contact'

  def contact_us
    if current_user.present?
      @user = Nomis::Elite2::UserApi.user_details(current_user)
      @contact = ContactSubmission.new(email_address: @user.email_address.first,
                                       name: @user.full_name_ordered,
                                       prison: PrisonService.name_for(
                                         @user.active_case_load_id)
      )
    else
      @contact = ContactSubmission.new
    end
  end

  def create_contact_us
    @user = Nomis::Elite2::UserApi.user_details(current_user) if current_user.present?
    @contact = ContactSubmission.new(
      name: help_params[:name],
      job_type: help_params[:job_type],
      email_address: help_params[:email_address],
      prison: help_params[:prison],
      message: help_params[:message],
      user_agent: request.headers['HTTP_USER_AGENT'],
      referrer: request.referer
    )
    if @contact.save
      ZendeskTicketsJob.perform_later(@contact) if Rails.configuration.zendesk_enabled

      redirect_path
    else
      render :contact_us
    end
  end

  def help; end

  def contact; end

private

  def redirect_path
    if current_user.present?
      redirect_to prison_dashboard_index_path(@user.active_case_load_id)
    else
      redirect_to help_path
    end
    flash[:notice] = 'Your message has been submitted'
  end

  def help_params
    # Unpermitted params when running development and test env
    # resulting in failures when attempting to submit form so
    # added the additional values in those scenarios.
    if Rails.env.production?
      params.permit(:message, :email_address, :name, :prison, :job_type)
    else
      params.permit(:message, :email_address, :name, :prison, :job_type, :utf8, :authenticity_token)
    end
  end
end
