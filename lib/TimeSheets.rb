#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# = TimeSheets.rb -- The TaskJuggler III Project Management Software
#
# Copyright (c) 2006, 2007, 2008, 2009, 2010 by Chris Schlaeger <cs@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

class TaskJuggler

  # This class holds the work related bits of a time sheet that are specific
  # to a single Task. This can be an existing Task or a new one identified by
  # it's ID String. For effort based task, it stores the remaining effort, for
  # other task the expected end date. For all tasks it stores the completed
  # work during the reporting time frame.
  class TimeSheetRecord

    attr_reader :task, :work
    attr_accessor :sourceFileInfo, :remaining, :expectedEnd, :status,
                  :priority, :name

    def initialize(timeSheet, task)
      # This is a reference to a Task object for existing tasks or an ID as
      # String for new tasks.
      @task = task
      # Add the new TimeSheetRecord to the TimeSheet it belongs to.
      (@timeSheet = timeSheet) << self
      # Work done will be measured in time slots.
      @work = nil
      # Remaining work will be measured in time slots.
      @remaining = nil
      @expectedEnd = nil
      # For new task, we also need to store the name.
      @name = nil
      # Reference to the JournalEntry object that holds the status for this
      # record.
      @status = nil
      @priority = 0
      @sourceFileInfo = nil
    end

    # Store the number of worked time slots. If the value is a Fixnum, it can
    # be directly assigned. A Float must is interpreted as percentage and must
    # be in the rage of 0.0 to 1.0.
    def work=(value)
      if value.is_a?(Fixnum)
        @work = value
      else
        # Must be percent value
        @work = @timeSheet.percentToSlots(value)
      end
    end

    # Perform all kinds of consistency checks.
    def check
      scIdx = @timeSheet.scenarioIdx
      taskId = @task.is_a?(Task) ? @task.fullId : @task
      # All TimeSheetRecords must have a 'work' attribute.
      if @work.nil?
        error('ts_no_work',
              "The time sheet record for task #{taskId} must " +
              "have a 'work' attribute to specify how much was done " +
              "for this task during the reported period.")
      end
      if @task.is_a?(Task)
        # This is already known tasks.
        if @task['effort', scIdx] > 0
          unless @remaining
            error('ts_no_remaining',
                  "The time sheet record for task #{taskId} must " +
                  "have a 'remaining' attribute to specify how much " +
                  "effort is left for this task.")
          end
        else
          unless @expectedEnd
            error('ts_no_expected_end',
                  "The time sheet record for task #{taskId} must " +
                  "have an 'end' attribute to specify the expected end " +
                  "of this task.")
          end
        end
      else
        # This is for new tasks.
        if @remaining.nil? && @expectedEnd.nil?
          error('ts_no_rem_or_end',
                "New task #{taskId} requires either a 'remaining' or a " +
                "'end' attribute.")
        end
      end

      if @work >= @timeSheet.daysToSlots(1) && @status.nil?
        error('ts_no_status_work',
              "You must specify a status for task #{taskId}.")
      end

      if @status
        if @work >= @timeSheet.daysToSlots(1) &&
          (@status.headline.empty? ||
           @status.headline == 'Your headline here!')
          error('ts_no_headline',
                "You must provide a headline for task #{@task.fullId}")
        end
        if @status.alertLevel > 0 && @status.summary.nil? &&
          @status.details.nil?
          error('ts_alert1_more_details',
                "Task #{taskId} has an elevated alert level and must " +
                "have a summary or details section.")
        end
        if @status.alertLevel > 1 && @status.details.nil?
          error('ts_alert2_more_details',
                "Task #{taskId} has a high alert level and must have " +
                "a details section.")
        end
      end
    end

    def taskId
      @task.is_a?(Task) ? @task.fullId : task
    end

    private

    def error(id, text)
      @timeSheet.message('error', id, text, @sourceFileInfo)
    end

    def warning(id, text)
      @timeSheet.message('warning', id, text, @sourceFileInfo)
    end

  end

  # The TimeSheet class stores the work related bits of a time sheet. For each
  # task it holds a TimeSheetRecord object. A time sheet is always bound to an
  # existing Resource.
  class TimeSheet

    attr_accessor :sourceFileInfo
    attr_reader :resource, :interval, :scenarioIdx

    def initialize(resource, interval, scenarioIdx)
      raise "Illegal resource" unless resource.is_a?(Resource)
      @resource = resource
      raise "Interval undefined" if interval.nil?
      @interval = interval
      raise "Sceneario index undefined" if scenarioIdx.nil?
      @scenarioIdx = scenarioIdx
      @sourceFileInfo = nil
      # This flag is set to true if at least one record was reported as
      # percentage.
      @percentageUsed = false
      # The TimeSheetRecord list.
      @records = []
    end

    # Add a new TimeSheetRecord to the list.
    def<<(record)
      @records.each do |r|
        if r.task == record.task
          error('ts_duplicate_task',
                "Duplicate records for task #{r.taskId}")
        end
      end
      @records << record
    end

    # Perform all kinds of consitency checks.
    def check
      totalSlots = 0
      @records.each do |record|
        record.check
        totalSlots += record.work
      end

      targetSlots = totalNetWorkingSlots
      # This is acceptable rounding error when checking the total reported
      # work.
      delta = 1
      if totalSlots < (targetSlots - delta)
        error('ts_work_too_low',
              "The total work to be reported for this time sheet " +
              "is #{workWithUnit(targetSlots)} but only " +
              "#{workWithUnit(totalSlots)} were reported.")
      end
      if totalSlots > (targetSlots + delta)
        error('ts_work_too_high',
              "The total work to be reported for this time sheet " +
              "is #{workWithUnit(targetSlots)} but " +
              "#{workWithUnit(totalSlots)} were reported.")
      end
    end

    # Compute the total number of potential working time slots of the
    # Resource. This is the sum of allocated, free and vacation slots.
    def totalGrossWorkingSlots
      project = @resource.project
      startIdx = project.dateToIdx(@interval.start)
      endIdx = project.dateToIdx(@interval.end)
      @resource.getAllocatedSlots(@scenarioIdx, startIdx, endIdx, nil) +
        @resource.getFreeSlots(@scenarioIdx, startIdx, endIdx) +
        @resource.getVacationSlots(@scenarioIdx, startIdx, endIdx)
    end

    # Compute the total number of actual working time slots of the
    # Resource. This is the sum of allocated, free time slots.
    def totalNetWorkingSlots
      project = @resource.project
      startIdx = project.dateToIdx(@interval.start)
      endIdx = project.dateToIdx(@interval.end)
      @resource.getAllocatedSlots(@scenarioIdx, startIdx, endIdx, nil) +
        @resource.getFreeSlots(@scenarioIdx, startIdx, endIdx)
    end

    # Report an error or warning to the TjMessageHandler. In case of an error
    # an exception is raised.
    def message(type, id, text, sourceFileInfo)
      unless text.empty?
        message = Message.new(id, type, text, @resource, nil, sourceFileInfo)
        resource.project.messageHandler.send(message)
      end

      # An empty strings signals an already reported error
      raise TjException.new, '' if type == 'error'
    end

    # Converts allocation percentage into time slots.
    def percentToSlots(value)
      @percentageUsed = true
      (totalGrossWorkingSlots * value).to_i
    end

    # Computes how many percent the _slots_ are of the total working slots in
    # the report time frame.
    def slotsToPercent(slots)
      slots.to_f / totalGrossWorkingSlots
    end

    def slotsToDays(slots)
      slots * @resource.project['scheduleGranularity'] /
        (60 * 60 * @resource.project.dailyWorkingHours)
    end

    def daysToSlots(days)
      ((days * 60 * 60 * @resource.project.dailyWorkingHours) /
       @resource.project['scheduleGranularity']).to_i
    end

    private

    def error(id, text)
      message('error', id, text, @sourceFileInfo)
    end

    def warning(id, text)
      message('warning', id, text, @sourceFileInfo)
    end

    def workWithUnit(slots)
      if @percentageUsed
        "#{(slotsToPercent(slots) * 100.0).to_i}%"
      else
        "#{slotsToDays(slots)} days"
      end
    end

  end

  # A class to hold all time sheets of a project.
  class TimeSheets < Array

    def initialize
      super
    end

    def check
      each { |s| s.check }
    end

  end

end
