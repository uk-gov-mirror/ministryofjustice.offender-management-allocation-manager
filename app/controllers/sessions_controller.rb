class SessionsController < ApplicationController
  def create
    identity = SignonIdentity.from_omniauth(request.env['omniauth.auth'])

    if identity
      session[:sso_data] = identity.to_session
      redirect_to session.delete(:redirect_path) || root_url
    else
      redirect_to root_url
    end
  end

  def destroy
    session.delete(:sso_data)
    redirect_to signout_url
  end

private

  def signout_url
    url = URI.parse(Rails.configuration.nomis_oauth_host)
    url.query = {
      redirect_uri: Rails.configuration.offender_manager_host,
      client_id: Rails.configuration.nomis_oauth_client_id
    }.to_query

    url.to_s
  end
end
