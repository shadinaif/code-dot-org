require 'concurrent'
class I18nStringUrlTracker
  @@buffer = Concurrent::Set[]
  @@update_thread = nil
  UPDATE_THREAD_PERIOD = 5 #seconds

  # starts a new thread which will periodically upload the recorded data.
  def self.create_update_worker_thread
    Thread.new do
      Thread.current.thread_variable_set(:buffer, Set[])
      loop do
        sleep UPDATE_THREAD_PERIOD
        upload_data
      end
    end
  end

  def self.upload_data
    # upload the data to Firehose.
    CDO.log.info "@@buffer=#{@@buffer}"
    @@buffer.clear
  end

  def self.log_association(string_key, url)
    return unless string_key && url
    # create an update_thread if there isn't one already.
    @@update_thread = create_update_worker_thread unless @@update_thread && @@update_thread.alive?
    # record the string : url association.
    @@buffer.add({string_key: string_key, url: url})
  end
end
