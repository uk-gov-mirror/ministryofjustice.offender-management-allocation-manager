module ApplicationHelper
  def replace_param(name, value)
    uri = URI.parse(request.original_url)

    query = Rack::Utils.parse_query(uri.query)
    query[name] = value

    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end
end
