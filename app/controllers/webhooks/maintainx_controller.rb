module Webhooks
  class MaintainxController < ApplicationController
    skip_before_action :verify_authenticity_token

    def work_order_created
      event = JSON.parse(request.body.read)
      work_order_id = event.dig("workOrderId")

      # List of services to call when a work order is created in MaintainX
      # Here we can add more services if needed in the future
      # For now, we only call the update due date service
      if work_order_id
        Maintainx::UpdateDuedateFromPriorityService.new(
          work_order_id,
          event.dig("newWorkOrder", "priority"),
        ).call
      end

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    def work_order_priority_changed
      event = JSON.parse(request.body.read)
      work_order_id = event.dig("workOrderId")
      priority = event.dig("newWorkOrder", "priority")

      if work_order_id && priority
        Maintainx::UpdateDuedateFromPriorityService.new(
          work_order_id,
          priority,
        ).call
      end

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end
  end
end