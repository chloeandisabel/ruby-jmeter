module RubyJmeter
  class ExtendedDSL < DSL
    def flood(token, params = {})
      RestClient.proxy = params[:proxy] if params[:proxy]
      begin
        file = Tempfile.new(['ruby-jmeter', '.jmx'])
        file.write(doc.to_xml(indent: 2))
        file.rewind

        flood_files = {
          file: File.new("#{file.path}", 'rb')
        }

        if params[:files]
          flood_files.merge!(Hash[params[:files].map.with_index { |value, index| [index, File.new(value, 'rb')] }])
          params.delete(:files)
        end

        response = RestClient.post "#{params[:endpoint] ? params[:endpoint] : 'https://api.flood.io'}/floods?auth_token=#{token}",
        {
          flood: {
            tool: 'jmeter',
            name: params[:name],
            notes: params[:notes],
            tag_list: params[:tag_list],
            threads: params[:threads],
            rampup: params[:rampup],
            duration: params[:duration],
            override_parameters: params[:override_parameters],
            started: params[:started],
            stopped: params[:stopped]
          },
          flood_files: flood_files,
          region: params[:region],
          multipart: true,
          content_type: 'application/octet-stream'
        }.merge(params)
        if response.code == 201
          logger.info "Flood results at: #{JSON.parse(response)["permalink"]}"
        else
          logger.fatal "Sorry there was an error: #{JSON.parse(response)["error"]}"
        end
      rescue => e
        logger.fatal "Sorry there was an error: #{JSON.parse(e.response)["error"]}"
      end
    end
  end
end
