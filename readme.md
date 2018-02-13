## Tripleseat api wrapper

this project is a quick and dirty ruby wrapper for the Tripleseat API documented [here](https://tripleseat.zendesk.com/hc/en-us/articles/205162108-API-Overview)


### coverage

API Endpoints

- [ ] Sites API
- [ ] Locations API
- [ ] Users API
- [x] Events API
- [ ] Bookings API
- [ ] Accounts API
- [ ] Contacts API
- [ ] Leads API
- [ ] Nested Objects API Information

### setup

1. get your own API keys from Tripleseat here: `http://galvanize.tripleseat.com/settings/api`
2. expose them as environment variables: `TRIPLESEAT_PUBLIC_TOKEN` and `TRIPLESEAT_SECRET_KEY`
3. see the example below

### example usage

```ruby
require_relative './tripleseat_events_wrapper'

search = TripleSeat::Search.new(location_ids: 3481, # this is the code for San Francisco
                    sort_direction: "asc",          # alt: desc
                    order: "event_start",           # alt: created_at, updated_at, name
                    query: "Accelerated Evening Course")

search.execute!.each do |e|
  puts "%12s  %-25.25s... %25.20s %25s" % [e.date, e.name, e.registration_url, e.galvanize_url]
end
```
