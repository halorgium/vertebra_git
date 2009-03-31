module VertebraGit
  module Actors
    class Watcher < Vertebra::Actor
      provides "/git"

      bind_op "/code/commit", :code_commit
      desc "/code/commit", "Announce a commit"
      def code_commit(operation, args)
        repository = args['repository'].last
        commit = args["commit"]
        puts "Got a commit for #{repository}"
        pp commit

        topic = commit['message'].split("\n").first
        ref =   commit['id'][0,7]
        author = commit['author']['name']
        message = "[#{repository}] #{topic} - #{ref} - #{author}"

        puts message

        args = {:channel => "#halorgium", :message => message)
        @agent.request("/irc/push", :single, args)
        true
      end
    end
  end
end
