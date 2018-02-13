require_relative './tripleseat_events_wrapper'

search = TripleSeat::Search.new(location_ids: 3481, # this is the code for San Francisco
                    sort_direction: "asc",          # alt: desc
                    order: "event_start",           # alt: created_at, updated_at, name
                    query: "Accelerated Evening Course")

search.execute!.each do |e|
  puts "%12s  %-25.25s... %25.20s %25s" % [e.date, e.name, e.registration_url, e.galvanize_url]
end
