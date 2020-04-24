require 'concurrent'
require 'cdo/firehose'

class I18nStringUrlTracker
  @@buffer = Concurrent::Set[]
  @@update_thread = nil
  UPDATE_THREAD_PERIOD = 300 #5 minutes

  # starts a worker thread which will periodically upload the recorded data.
  def self.create_update_worker_thread
    Thread.new do
      Thread.current.thread_variable_set(:buffer, Set[])
      loop do
        sleep UPDATE_THREAD_PERIOD
        upload_data
      end
    end
  end

  # sends the buffered string:url association data to Firehose.
  def self.upload_data
    # upload the data to Firehose.
    FirehoseClient.instance.put_record_batch(@@buffer)
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
