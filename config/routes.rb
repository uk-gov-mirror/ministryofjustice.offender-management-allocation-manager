Rails.application.routes.draw do
  root to: 'dashboard#index'

  get '/status', to: 'status#index'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'

  get('health' => 'health#index')

  get('/allocations'           => 'allocations#index')
  get('/allocations/allocated' => 'allocations#allocated')
  get('/allocations/pending'   => 'allocations#pending_allocation')
  get('/allocations/waiting'   => 'allocations#pending_tier')

  get('/poms' => 'poms#index')
  get('/poms/:id' => 'poms#show', as: 'poms_show')
  get('/poms/:id/edit' => 'poms#edit', as: 'poms_edit')

  resource :allocate_prison_offender_managers, only: %i[show edit]
end
