Flipflop.configure do
  strategy :active_record
  strategy :default

  feature :early_allocation,
          default: true,
          description: 'Early Allocation to probation team'
end
