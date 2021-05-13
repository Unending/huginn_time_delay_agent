require 'date'

module Agents
  class TimeDelayAgent < Agent
    default_schedule 'every_1h'

    description <<-MD
      The Time Delay Agent stores received events and re-emits them at a specified time.

      `delay_untill` Event field with the date (and time) after which the event can be re-emitted. Use [Liquid templating](https://github.com/huginn/huginn/wiki/Formatting-Events-using-Liquid) to specify which field of the received event should be used.
      Dates (and times) can be dynamically generated using liquid templating; for example `{{'now' | date: '%s' | plus: 86400 | date: '%Y-%m-%d %H:%M:%S'}}` to delay an event one day.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days that you anticipate passing without this Agent receiving an incoming Event.
    MD

    def default_options
      {
        'expected_receive_period_in_days' => '10',
        'delay_untill' => '{{ date }}'
      }
    end

    def validate_options
      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      last_receive_at && last_receive_at > options['expected_receive_period_in_days'].to_i.days.ago && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolation_context.stack do
          write_memory(interpolated(event), event)
        end
      end
    end

    def check
      if memory && memory.length > 0
        now = Time.now

        memory['events'].each do |mem_event|
          release_at = mem_event['delay_untill']

          if release_at < now
            create_event payload: mem_event['payload']
            memory['events'].delete(mem_event)
          end
        end
      end
    end

    private

    def write_memory(opts, event = nil)
      delay_untill = opts['delay_untill']
      delay_untill_parsed = Time.zone.parse(delay_untill)

      if delay_untill_parsed.is_a?(Time)
        memory['events'] ||= []
        memory['events'] << { 'delay_untill': delay_untill_parsed,
                              'payload': event.payload}
      else
        error("\"#{delay_untill}\" is not a valid datetime.")
      end
    end
  end
end
