require_relative './tripleseat_events_wrapper'

search = TripleSeat::Search.new(location_ids: 3481, # this is the code for San Francisco
                    sort_direction: "asc",          # alt: desc
                    order: "event_start",           # alt: created_at, updated_at, name
                    query: ARGV[0] || "Python Accelerated")
                    # query: "Javascript Accelerated")
                    # query: "Accelerated Evening Course")

puts "%12s  %-35.35s %-70s %-25s" % ["Date", "Name", "Registration URL", "Event URL"]
puts "%12s  %-35.35s %-70s %-25s" % ["----", "----", "----------------", "--------"]

search.execute!.each do |e|
  puts "%12s  %-35.35s %-70s %-25s" % [e.date, e.name, e.registration_url, e.url]
end
