# frozen_string_literal: true

require 'faraday'
require 'json'

class Maintainx::UpdateDuedateService
    API_BASE = "https://api.getmaintainx.com/v1"
    API_TOKEN = Rails.application.credentials.dig(:maintainx_api_token)


  def initialize(work_order_id)
    @work_order_id = work_order_id
    @client = Faraday.new(url: API_BASE) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.headers['Authorization'] = "Bearer #{API_TOKEN}"
      conn.headers['Content-Type'] = 'application/json'
    end
  end

  def call
    work_order = get_work_order
    return unless work_order

    priority = work_order.dig('workOrder', 'priority')
    new_due_date = calculate_new_due_date(priority)
    return unless new_due_date

    update_work_order_due_date(new_due_date)
  end

  private

  def get_work_order
    response = @client.get("workorders/#{@work_order_id}")
    return response.body if response.success?

    Rails.logger.error("Failed to fetch work order: #{response.status} - #{response.body}")
    nil
  end

  def calculate_new_due_date(priority)
    new_due_date = case priority&.downcase
    when 'high'
      1.day.from_now
    when 'medium'
      3.days.from_now
    when 'low'
      7.days.from_now
    else
      nil
    end

    new_due_date&.iso8601
  end

  def update_work_order_due_date(due_date)
    response = @client.patch("workorders/#{@work_order_id}") do |req|
      req.body = { dueDate: due_date }
    end

    unless response.success?
      Rails.logger.error("Failed to update due date: #{response.status} - #{response.body}")
    end
  end
end