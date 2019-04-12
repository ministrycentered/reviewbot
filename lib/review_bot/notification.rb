# frozen_string_literal: true
require 'liquid'

module ReviewBot
  class Notification
    def initialize(pull_request:, suggested_reviewers:, completed_reviewers:, author:, template:)
      @pull_request = pull_request
      @suggested_reviewers = suggested_reviewers
      @completed_reviewers = completed_reviewers
      @author = author
      @template = template
    end

    attr_reader :pull_request, :suggested_reviewers, :completed_reviewers, :author, :template

    def message
      @template = Liquid::Template.parse(template || default_message)
      @template.render(
        'bullet' => '•',
        'pull_request_number' => pull_request.number,
        'pull_request_title' => pull_request.title,
        'pull_request_html_url' => pull_request.html_url,
        'needed_review_type' => needed_review_type,
        'suggested_emojis' => suggested_emojis,
        'completed_emojis' => completed_emojis,
        'ez_labels' => ez_labels,
        'plus_ones' => plus_ones,
        'author_emoji' => author_emoji
      )
    end

    private

    def needed_review_type
      pull_request.needs_first_review? ? 'first review' : 'second review'
    end

    def completed_emojis
      completed_reviewers.map(&:not_user_slack_emoji).join(' ')
    end

    def suggested_emojis
      suggested_reviewers.map(&:slack_emoji).join(' ')
    end

    def ez_labels
      pull_request.ez? ?  ":ez:" : ''
    end

    def plus_ones
      pull_request.needs_first_review? ? '' : ':plus_one:'
    end

    def author_emoji
      author&.slack_emoji
    end

    def default_message
      '{{bullet}} #{{pull_request_number}} <{{pull_request_html_url}}|{{pull_request_title}}> needs a *{{needed_review_type}}* from {{suggested_emojis}}'
    end
  end
end
