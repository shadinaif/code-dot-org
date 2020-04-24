require 'singleton'
require 'aws-sdk-firehose'

# A wrapper client to the AWS Firehose service.
# @example
#   FirehoseClient.instance.put_record(
#     {
#       study: 'underwater basket weaving', # REQUIRED
#       study_group: 'control',             # OPTIONAL
#       script_id: script.id,               # OPTIONAL
#       level_id: level.id,                 # OPTIONAL
#       project_id: project.id,             # OPTIONAL
#       user_id: user.id,                   # OPTIONAL
#       event: 'drowning',                  # REQUIRED
#       data_int: 2,                        # OPTIONAL
#       data_float: 1.8,                    # OPTIONAL
#       data_string: 'hello world',         # OPTIONAL
#       data_json: "{\"key\":\"value\"}"    # OPTIONAL
#     }
#   )

STREAM_NAME = 'analysis-events'.freeze

class FirehoseClient
  include Singleton

  REGION = 'us-east-1'.freeze

  # Initializes the @firehose to an AWS Firehose client.
  def initialize
    if [:development, :test].include? rack_env
      return
    end
    @firehose = Aws::Firehose::Client.new(region: REGION)
  end

  def put_record_batch(datas)
    return unless Gatekeeper.allows('firehose', default: true)
    return if datas.nil_or_empty?

    datas_with_common_values = []
    datas.each do |data|
      datas_with_common_values << {data: add_common_values(data)}
    end

    if [:development, :test].include? rack_env
      CDO.log.info "Skipped sending record to #{STREAM_NAME}: "
      CDO.log.info datas
      return
    end

    # AWS Firehose documents that put_record_batch can only handle 500
    # records at a time so we will break up the data into 500 chunks and send
    # it.
    firehose_max_records_batch = 500
    i = 0
    while i < datas_with_common_values.size
      # get a batch of records to send
      batch_end = i + firehose_max_records_batch
      datas_with_common_values_batch = datas_with_common_values[i..batch_end]
      @firehose.put_record_batch(
        {
          delivery_stream_name: STREAM_NAME,
          records: datas_with_common_values_batch.to_json
        }
      )
      i += firehose_max_records_batch
    end
  # Swallow and log all errors because an issue sending analytics should not prevent the caller from continuing.
  rescue StandardError => error
    # TODO(suresh): if the exception is Firehose ServiceUnavailableException, we should consider
    # backing off and retrying.
    # See http://docs.aws.amazon.com/sdkforruby/api/Aws/Firehose/Client.html#put_record-instance_method.
    Honeybadger.notify(error)
  end

  # Posts a record to the analytics stream.
  # @param data [hash] The data to insert into the stream.
  def put_record(data)
    put_record_batch([data])
  end

  private

  # Adds common key-value pairs to the data hash.
  # @param data [hash] The data to add the key-value pairs to.
  # @return [hash] The data, including the newly added key-value pairs.
  def add_common_values(data)
    data_with_common_values = data.merge(
      created_at: DateTime.now,
      environment: rack_env,
      device: 'server-side'.to_json
    )
    data_with_common_values[user_id] ||= current_user.id if current_user
    data_with_common_values
  end
end
