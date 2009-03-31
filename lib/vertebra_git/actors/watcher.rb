module VertebraGit
  module Actors
    class Watcher < Vertebra::Actor
      def initialize(*args)
        super

        @announce_ircnet, @announce_channel = args.first
      end

      provides "/code/commit"

      bind_op "/code/commit", :code_commit
      desc "/code/commit", "Announce a commit"
      def code_commit(operation, args)
        repository = args['repository']
        repository_name = repository.last
        commit = args["commit"]
        puts "Got a commit for #{repository_name}"

        topic = commit['message'].split("\n").first
        ref =   commit['id'][0,7]
        author = commit['author']['name']

        send_to_irc "[#{repository_name}] #{topic} - #{ref} - #{author}"

        args = {:repository => repository, :commit => commit}
        @agent.request("/ci/build", :single, args) do |response|
          puts "build pushed: #{response.inspect}"
        end
        true
      end

      def send_to_irc(message)
        puts "About to send: #{message}"
        args = {
          :ircnet => Vertebra::Utils.resource(@announce_ircnet),
          :channel => Vertebra::Utils.resource(@announce_channel),
          :message => message
        }
        @agent.request("/irc/push", :single, args) do |response|
          puts "message pushed: #{response.inspect}"
        end
      end
    end
  end
end
