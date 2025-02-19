# LogCollector is a simple container that collects log messages and exceptions
# when executing a task. It can also time block execution and log the result.
#
# LogCollector is helpful when we want to
# - Prevent non-fatal errors from stopping process execution but still want to know about them.
# - Bubble up combined errors and info from lower levels to higher levels, or to external components
#   such as HoneyBadger and Slack.
#
class LogCollector
  attr_reader :exceptions, :logs, :task_name

  def initialize(task_name = nil)
    @task_name = task_name

    # List of rescued exceptions
    @exceptions = []

    # List of message logs
    @logs = []
  end

  # Execute a block and time it.
  # Save exception if caught, do not re-raise. Caller's flow will continue as normal.
  #
  # @param action_name [string] a friendly name of the block being executed
  def time(action_name = nil)
    return unless block_given?
    start_time = Time.now

    yield

    info("#{action_name || 'Unnamed'} action completed without error in"\
      " #{self.class.get_friendly_time(Time.now - start_time)}."
    )
  rescue StandardError => e
    error("#{action_name || 'Unnamed'} action exited with error in"\
      " #{self.class.get_friendly_time(Time.now - start_time)}."
    )
    record_exception(e)
  end
  alias_method :time_and_continue, :time

  # Execute a block and time it.
  # Re-raise exception if caught, do not save. This will disrupt the caller's flow.
  #
  # @param action_name [string] friendly name for the given block
  #
  # @raise [StandardError] error encoutered when executing the given block
  def time!(action_name = nil)
    return unless block_given?
    start_time = Time.now

    yield

    info("#{action_name || 'Unnamed'} action completed without error in"\
      " #{self.class.get_friendly_time(Time.now - start_time)}."
    )
  rescue StandardError
    error("#{action_name || 'Unnamed'} action exited with error in"\
      " #{self.class.get_friendly_time(Time.now - start_time)}. Exception re-raised!"
    )

    # To be handled by caller
    raise
  end
  alias_method :time_and_raise!, :time!

  def info(message)
    logs << "[#{Time.now}] INFO: #{message}"
  end

  def error(message)
    logs << "[#{Time.now}] ERROR: #{message}"
  end

  def record_exception(e)
    exceptions << e
    error("Exception caught: #{e.inspect}. Stack trace:\n#{e.backtrace.join("\n")}")
  end

  def ok?
    exceptions.blank?
  end

  def to_s
    str = "#{task_name} task recorded #{exceptions.size} exceptions(s) and #{logs.size} log message(s).\n"
    str + logs.join("\n")
  end
  alias_method :inspect, :to_s

  def self.get_friendly_time(value)
    "#{value.round(2)} seconds" if value.respond_to?(:round)
  end
end
