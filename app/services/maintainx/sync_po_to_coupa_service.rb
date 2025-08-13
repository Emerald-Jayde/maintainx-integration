# frozen_string_literal: true

require 'faraday'
require 'json'
require 'builder'

class Maintainx::SyncPoToCoupaService
  MAINTAINX_API_TOKEN = Rails.application.credentials.dig(:maintainx_api_token)
  COUPA_API_TOKEN     = Rails.application.credentials.dig(:coupa_api_token)
  MAINTAINX_API_BASE  = "https://api.getmaintainx.com/v1"
  COUPA_API_BASE      = "https://your.coupa.domain.com/api/purchase_orders"

  def initialize(maintainx_po_id)
    @maintainx_po_id = maintainx_po_id
  end

  def call
    po_data = get_maintainx_po
    return unless po_data

    xml_payload = build_coupa_po_xml(po_data)
    create_in_coupa(xml_payload)
  end

  private

  def get_maintainx_po
    conn = Faraday.new(url: MAINTAINX_API_BASE) do |f|
      f.headers['Authorization'] = "Bearer #{MAINTAINX_API_TOKEN}"
      f.headers['Content-Type']  = 'application/json'
      f.response :json
    end

    response = conn.get("purchase_orders/#{@maintainx_po_id}")
    return response.body if response.success?

    Rails.logger.error("Failed to fetch MaintainX PO: #{response.status}")
    nil
  end

  def build_coupa_po_xml(data)
    purchase_order_data = data.dig("newPurchaseOrder")
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!

    xml.purchase_order do
      xml.po_number purchase_order_data.dig("overrideNumber")
      xml.payment_term do
        # payment_term to be mapped
      end

      xml.order_lines do
        purchase_order_data.dig("items").each do |item|
          xml.order_line do
            xml.description item.dig("name")
            xml.quantity item.dig("quantityOrdered")
            xml.price item.dig("unitCost")
            xml.account do
              # account to be mapped
            end
          end
        end
      end
    end
  end

  def create_in_coupa(xml_payload)
    conn = Faraday.new(url: COUPA_API_BASE) do |f|
      f.headers['Accept']        = 'application/xml'
      f.headers['Content-Type']  = 'application/xml'
      f.headers['X-COUPA-API-KEY'] = COUPA_API_TOKEN
    end

    response = conn.post do |req|
      req.body = xml_payload
    end

    if response.success?
      Rails.logger.info("Successfully synced to Coupa. PO ID: #{response.body}")
    else
      Rails.logger.error("Coupa sync failed: #{response.status} - #{response.body}")
    end
  end
end
