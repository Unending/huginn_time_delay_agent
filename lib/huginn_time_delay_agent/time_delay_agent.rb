require 'date'

module Agents
  class TimeDelayAgent < Agent
    include FormConfigurable

    default_schedule 'every_1h'

    description <<-MD
      The TimeDelayAgent stores received events and emits copies of them at a specified time.
    MD

    def default_options
      {
        'expected_receive_period_in_days' => '10',
        'delay_untill' => '{{ date }}'
      }
    end

    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :delay_untill, type: :string

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
      memory['events'] ||= []
      memory['events'] << { 'delay_untill': Time.zone.parse(opts['delay_untill']),
                            'payload': event.payload}
    end
  end
end
