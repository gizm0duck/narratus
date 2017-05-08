module Narratus
  module Railties
    module ControllerExtensions
      extend ActiveSupport::Concern
      # extend ::NewRelic::Agent::MethodTracer

      protected

      def append_info_to_payload(payload)
        super
        # TODO: document the reasons for these various manipulations (JN)
        cookies_out = request.cookies.reject{|k, v| !(String === v || Integer === v || Hash === v || Array === v) }
        headers_out = request.headers.reject{|k, v| !(String === v || Integer === v || Hash === v || Array === v) }
        dispatch_cookies_out = request.headers["action_dispatch.cookies"].reject{|k, v| !(String === v || Integer === v || Hash === v || Array === v) }
        headers_out.reject!{|k,v| !(k==k.upcase)}

        request_data = {
          params: params,
          headers: Hash[*headers_out.sort.flatten],
          cookies: Hash[*cookies_out.sort.flatten],
          dispatch_cookies: Hash[*dispatch_cookies_out.sort.flatten],
          server_ip: request.remote_ip,
          uuid: request.uuid,
          client_ip: request.ip,
        }
        response_data = {
          header: response.header,
          status: response.status,
        }

        payload.merge! request_data
        payload[:response] = response_data
      end

    end
  end
end

ActiveSupport.on_load(:action_controller) do
  include Narratus::Railties::ControllerExtensions
end
