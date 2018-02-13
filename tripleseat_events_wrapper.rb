require 'parallel'
require 'oauth'
require 'json'

module TripleSeat

  class Event
    FIELDS = {
      location: "location_id",
      date: "event_date",
      name: "name",
      registration_url: "custom:Registration Url",
      galvanize_url: "custom:Galvanize Url"
    }

    def initialize(event)
      FIELDS.each do |k,v|
        if (evt = v.split(/custom:/)).length > 1
          value = custom_field_value(event, evt.last)
        else
          value = event[v]
        end

        self.class.class_eval("attr_reader :#{k}")
        instance_variable_set("@#{k}", value)
      end
    end

    def self.from_json(event)
      Event.new(event)
    end

    def custom_field_value(event, custom_field_name)
      unless event["custom_fields"].empty? # record may not have custom fields
        field = event["custom_fields"].select{|f| f["custom_field_name"] == custom_field_name}.first
        return field["value"] unless field.nil? # record may not have the field we're looking for
      end
    end
  end


  class Search
    API_URL = "http://api.tripleseat.com"
    ROOT = "/v1/events/search.json?"
    PUBLIC_TOKEN = ENV["TRIPLESEAT_PUBLIC_TOKEN"] || fail("TRIPLESEAT_PUBLIC_TOKEN is required")
    SECRET_KEY =  ENV["TRIPLESEAT_SECRET_KEY"] || fail("TRIPLESEAT_SECRET_KEY is required")

    FIELDS = %i[location_ids sort_direction order status query]

    attr_reader :results, :more

    def initialize(args = {})
      @results = []
      @search_parameters = []

      args.each do |k,v|
        instance_variable_set("@#{k}", v) if FIELDS.include? k
        @search_parameters.push(k)
      end

      connect!
    end

    def execute!
      # get the first page
      resp = @a.get(construct_url)
      pages, results = JSON.parse(resp.body).values

      pages = should_we_continue?(pages)

      unless pages > 1
        # we only had one page so handle it
        @results = results.map{ |e| Event.from_json(e) }
      else
        # otherwise we've got lots of pages build a list of urls
        urls = Array.new(pages) {|i| "#{construct_url}page=#{i += 1}" }

        # and parellalize the work
        # https://github.com/grosser/parallel
        resp = Parallel.map(urls) do |url|
          @a.get(url)
        end

        # _, results = JSON.parse(resp.map(&:body).flatten).values

        @results = resp.map{|r| JSON.parse(r.body)["results"]}.flatten.map{ |e| Event.from_json(e) }
      end

      @results
    end

    private
    def should_we_continue?(pages)
      return pages if pages < 10

      puts "found #{pages} pages.  do you want to continue? [yN]"
      user = gets.chomp
      unless user.downcase == "y"
        puts "user quit"
        exit
      else
        puts "how many pages do you want to retrieve? [max #{pages}]"
        return gets.chomp.to_i
      end
    end

    def construct_url
      url = @search_parameters.reduce(ROOT) do |acc, v|
        iv="@#{v}".to_sym
        "#{acc}#{v}=#{instance_variable_get(iv)}&"
      end

      URI.escape(url)
    end

    def connect!
      consumer = OAuth::Consumer.new(PUBLIC_TOKEN, SECRET_KEY, {:site => API_URL})
      access_token = OAuth::AccessToken.new(consumer)
      @a = access_token
    end
  end

end

# GET /v1/events/search.(xml | json)?{search params}
# Search for events using filtering parameters (listed below). Append parameters together using & (e.g., ?query=kevin&sort_direction=desc&order=created_at).
#
# Search Parameters and values
# query - searches for events by name, contact, account, email, phone
# order - created_at, updated_at, name, event_start (datetime)
# sort_direction - desc, asc
# contact_id - Contact ID
# account_id - Account ID
# status - prospect, tentative, definite, closed, or lost (Array or comma separated string)
# event_start_date - mm/dd/yyyy (also requires end date)
# event_end_date - mm/dd/yyyy (also requires start date)
# event_created_start_date - mm/dd/yyyy (also requires end date)
# event_created_end_date - mm/dd/yyyy (also requires start date)
# event_updated_start_date - mm/dd/yyyy (also requires end date)
# event_updated_end_date - mm/dd/yyyy (also requires start date)
# room_ids - comma separated list of room ID's to match on
# location_ids - comma separated list of location ID's to match on
# custom_field_values[][custom_field_id] - Custom Field ID (pair with a custom_field_value)
# custom_field_values[][custom_field_value] - Custom Field Value (pair with a custom_field_id)
# page - (1..9999999)
