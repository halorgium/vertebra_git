module VertebraGit
  module Actors
    class Watcher < Vertebra::Actor
      def initialize(*args)
        super

        @announce_ircnet, @announce_channel = args.first
      end

      bind_op "/code/commit"
      desc "Announce a commit"
      def commit(operation, args)
        repository = args['repository']
        repository_name = repository.last
        commit = args["commit"]
        puts "Got a commit for #{repository_name}"

        topic = commit['message'].split("\n").first
        ref =   commit['id'][0,7]
        author = commit['author']['name']

        send_to_irc "[#{repository_name}] <commit> #{topic} - #{ref} - #{author}"

        args = {:repository => repository, :commit => commit}
        @agent.request("/ci/build", :single, args) do |response|
          puts "build pushed: #{response.inspect}"
        end
        true
      end

      bind_op "/code/built"
      desc "Announce a build"
      def code_built(operation, args)
        repository = args['repository']
        repository_name = repository.last
        commit = args["commit"]

        topic = commit['message'].split("\n").first
        ref =   commit['id'][0,7]
        author = commit['author']['name']

        prefix = "[#{repository_name}] <build> #{topic} - #{ref} - #{author}"

        if args['result']
          send_to_irc "#{prefix} passed"
        else
          send_to_irc "#{prefix} failed"
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
