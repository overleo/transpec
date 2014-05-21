# coding: utf-8

require 'rainbow'

module Transpec
  class Report
    attr_reader :records, :conversion_errors, :syntax_errors

    def initialize
      @records = []
      @conversion_errors = []
      @syntax_errors = []
    end

    def <<(other)
      records.concat(other.records)
      conversion_errors.concat(other.conversion_errors)
      syntax_errors.concat(other.syntax_errors)
      self
    end

    def unique_record_counts
      record_counts = Hash.new(0)

      records.each do |record|
        record_counts[record] += 1
      end

      sorted_record_counts = record_counts.sort_by do |record, count|
        [-count, record.original_syntax_type, record.converted_syntax_type]
      end

      Hash[sorted_record_counts]
    end

    def colored_summary(options = nil)
      options ||= { bullet: nil, separate_by_blank_line: false }

      summary = ''

      unique_record_counts.each do |record, count|
        summary << "\n" if options[:separate_by_blank_line] && !summary.empty?
        summary << format_record(record, count, options[:bullet])
      end

      summary
    end

    def summary(options = nil)
      without_color { colored_summary(options) }
    end

    def colored_stats
      base_color = if !conversion_errors.empty?
                     :magenta
                   elsif annotation_count.nonzero?
                     :yellow
                   else
                     :green
                   end

      conversion_incomplete_warning_stats(base_color) + error_stats(base_color)
    end

    def stats
      without_color { colored_stats }
    end

    private

    def rainbow
      @rainbow ||=  Rainbow.new
    end

    def colorize(string, *args)
      rainbow.wrap(string).color(*args)
    end

    def without_color
      original_coloring_state = rainbow.enabled
      rainbow.enabled = false
      value = yield
      rainbow.enabled = original_coloring_state
      value
    end

    def format_record(record, count, bullet = nil)
      entry_prefix = bullet ? bullet + ' ' : ''
      indentation = if bullet
                      ' ' * entry_prefix.length
                    else
                      ''
                    end

      text = entry_prefix + colorize(pluralize(count, 'conversion'), :cyan) + "\n"
      text << indentation + '  ' + colorize('from: ', :cyan) + record.original_syntax + "\n"
      text << indentation + '    ' + colorize('to: ', :cyan) + record.converted_syntax + "\n"
    end

    def conversion_incomplete_warning_stats(color)
      text = pluralize(records.count, 'conversion') + ', '
      text << pluralize(conversion_errors.count, 'incomplete') + ', '
      text << pluralize(annotation_count, 'warning') + ', '
      colorize(text, color)
    end

    def error_stats(base_color)
      color = if syntax_errors.empty?
                base_color
              else
                :red
              end

      colorize(pluralize(syntax_errors.count, 'error'), color)
    end

    def pluralize(number, thing, options = {})
      text = ''

      if number == 0 && options[:no_for_zero]
        text = 'no'
      else
        text << number.to_s
      end

      text << " #{thing}"
      text << 's' unless number == 1

      text
    end

    def annotation_count
      records.count(&:annotation)
    end
  end
end
