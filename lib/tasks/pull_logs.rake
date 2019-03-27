require 'rake'

namespace :pull_logs do
  desc 'Retrieve the logs from the current staging pods'
  task staging: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    LogPuller.new('offender-management-staging').pull
  end

  desc 'Retrieve the logs from the current production pods'
  task production: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    LogPuller.new('offender-management-production').pull
  end
end

class LogPuller
  def initialize(namespace)
    @namespace = namespace
  end

  def pull
    threads = pods.map {|pod|
      Thread.new {
        read(pod, @namespace)
      }
    }
    blobs = threads.map {|t|
      t.join
      t[:output]
    }

    pp blobs.flatten.sort_by { |record| record['@timestamp'] }
    #pp lines
  end

  def read(pod, namespace)
    cmd = log_command_string(pod, namespace)
    json_lines = `#{cmd}`.lines.map(&:chomp)

    non_blobs = []
    blobs = json_lines.map { |line|
      begin
        blob = JSON.parse(line)
        blob['pod'] = parse_pod(pod)
        blob
      rescue JSON::ParserError
        non_blobs << "#{parse_pod(pod)} => #{line}"
        nil
      end
    }

    Thread.current[:output] = blobs.compact
    Thread.current[:lines] = non_blobs
  end

private

  def pods
    @pods ||= `kubectl get pods --namespace #{@namespace}`.lines.drop(1).map{ |line|
      line.split(' ')[0]
    }
  end

  def parse_pod(pod)
    pod[19..-1]
  end

  def log_command_string(pod, namespace)
    "kubectl logs #{pod} allocation-manager --namespace #{namespace}"
  end
end

