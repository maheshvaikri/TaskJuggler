#
# TjpSyntaxRules - TaskJuggler
#
# Copyright (c) 2006, 2007 by Chris Schlaeger <cs@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# $Id$
#

# This module contains the rule definition for the TJP syntax. Every rule is
# put in a function who's name must start with rule_. The functions are not
# necessary but make the file more readable and receptable to syntax folding.
module TjpSyntaxRules

  def rule_allocationAttribute
    newRule('allocationAttribute')
    optional
    repeatable

    newPattern(%w( _alternative !resourceId !moreAlternatives ), Proc.new {
      [ 'alternative', [ @val[1] ] + @val[2] ]
    })
    doc('alternative', <<'EOT'
Specify which resources should be allocated to the task. The optional
attributes provide numerous ways to control which resource is used and when
exactly it will be assigned to the task. Shifts and limits can be used to
restrict the allocation to certain time intervals or to limit them to a
certain maximum per time period.
EOT
       )

    newPattern(%w( _select !allocationSelectionMode ), Proc.new {
      [ 'select', @val[1] ]
    })
    doc('select', <<'EOT'
The select functions controls which resource is picked from an allocation and
it's alternatives. The selection is re-evaluated each time the resource used
in the previous time slot becomes unavailable.

Even for non-persistent allocations a change in the resource selection only
happens if the resource used in the previous (or next for ASAP tasks) time
slot has become unavailable.
EOT
       )

    singlePattern('_persistent')
    doc('persistent', <<'EOT'
Specifies that once a resource is picked from the list of alternatives this
resource is used for the whole task. This is useful when several alternative
resources have been specified. Normally the selected resource can change after
each break. A break is an interval of at least one timeslot where no resources
were available.
EOT
       )

    singlePattern('_mandatory')
    doc('mandatory', <<'EOT'
Makes a resource allocation mandatory. This means, that for each time slot
only then resources are allocated when all mandatory resources are available.
So either all mandatory resources can be allocated for the time slot, or no
resource will be allocated.
EOT
       )
  end

  def rule_allocationAttributes
    newOptionsRule('allocationAttributes', 'allocationAttribute')
  end

  def rule_allocationSelectionMode
    newRule('allocationSelectionMode')
    singlePattern('_maxloaded')
    descr('Pick the available resource that has been used the most so far.')

    singlePattern('_minloaded')
    descr('Pick the available resource that has been used the least so far.')

    singlePattern('_minallocated')
    descr(<<'EOT'
Pick the resource that has the smallest allocation factor. The
allocation factor is calculated from the various allocations of the resource
across the tasks. This is the default setting.)
EOT
         )

    singlePattern('_order')
    descr('Pick the first available resource from the list.')

    singlePattern('_random')
    descr('Pick a random resource from the list.')
  end

  def rule_argumentList
    newRule('argumentList')
    optional
    newPattern(%w( _( !operation !moreArguments _) ), Proc.new {
      [ @val[0] ] + @val[1].nil? ? [] : @val[1]
    })
  end

  def rule_bookingAttributes
    newRule('bookingAttributes')
    optional
    repeatable

    newPattern(%w( _overtime $INTEGER ), Proc.new {
      if @val[1] < 0 || @val[1] > 2
        error('overtime_range',
              "Overtime value #{@val[1]} out of range (0 - 2).", @property)
      end
      @booking.overtime = @val[1]
    })
    doc('booking.overtime', <<'EOT'
This attribute enables bookings to override working hours and vacations.
EOT
       )

    newPattern(%w( _sloppy $INTEGER ), Proc.new {
      if @val[1] < 0 || @val[1] > 2
        error('sloppy_range',
              "Sloppyness value #{@val[1]} out of range (0 - 2).", @property)
      end
      @booking.sloppy = @val[1]
    })
    doc('booking.sloppy', <<'EOT'
Controls how strict TaskJuggler checks booking intervals for conflicts with
vacation and other bookings. In case the error is suppressed the booking will
not overwrite the existing bookings. It will avoid the already assigned
intervals during booking.
EOT
       )
  end

  def rule_bookingBody
    newOptionsRule('bookingBody', 'bookingAttributes')
  end

  def rule_calendarDuration
    newRule('calendarDuration')
    newPattern(%w( !number !durationUnit ), Proc.new {
      convFactors = [ 60, # minutes
                      60 * 60, # hours
                      60 * 60 * 24, # days
                      60 * 60 * 24 * 7, # weeks
                      60 * 60 * 24 * 30.4167, # months
                      60 * 60 * 24 * 365 # years
                     ]
      (@val[0] * convFactors[@val[1]] / @project['scheduleGranularity']).to_i
    })
    arg(0, 'value', 'A floating point or integer number')
  end

  def rule_columnBody
    newOptionsRule('columnBody', 'columnOptions')
  end

  def rule_columnDef
    newRule('columnDef')
    newPattern(%w( !columnId !columnBody ), Proc.new {
      @val[0]
    })
  end

  def rule_columnId
    newRule('columnId')
    newPattern(%w( !reportableAttributes ), Proc.new {
      title = @reportElement.defaultColumnTitle(@val[0])
      @column = TableColumnDefinition.new(@val[0], title)
    })
    doc('columnid', <<'EOT'
In addition to the listed IDs all user defined attributes can be used as
column IDs.
EOT
       )
  end

  def rule_columnOptions
    newRule('columnOptions')
    optional
    repeatable
    newPattern(%w( _title $STRING ), Proc.new {
      @column.title = @val[1]
    })
    doc('columntitle', <<'EOT'
Specifies an alternative title for a report column.
EOT
       )
    arg(1, 'text', 'The new column title.')
  end

  def rule_declareFlagList
    newListRule('declareFlagList', '$ID')
  end

  def rule_durationUnit
    newRule('durationUnit')

    newPattern(%w( _min ), Proc.new { 0 })
    descr('minutes')

    newPattern(%w( _h ), Proc.new { 1 })
    descr('hours')

    newPattern(%w( _d ), Proc.new { 2 })
    descr('days')

    newPattern(%w( _w ), Proc.new { 3 })
    descr('weeks')

    newPattern(%w( _m ), Proc.new { 4 })
    descr('months')

    newPattern(%w( _y ), Proc.new { 5 })
    descr('years')
  end

  def rule_export
    newRule('export')
    newPattern(%w( !exportHeader !exportBody ))
    doc('export', <<'EOT'
The export report looks like a regular TaskJuggler file but contains fixed
start and end dates for all tasks. The tasks only have start and end times,
their description and their project id listed. No other attributes are
exported unless they are requested using the taskattributes attribute. The
contents also depends on the extension of the file name. If the file name ends
with .tjp a complete project with header, resource and shift definitions is
generated. In case it ends with .tji only the tasks and resource allocations
are exported.

If specified the resource usage for the tasks is reported as well. But only
those allocations are listed that belong to tasks listed in the same export
report.

The export report can be used to share certain tasks or milestones with other
projects or to save past resource allocations as immutable part for future
scheduling runs. When an export report is included the project IDs of the
included tasks must be declared first with the project id property.`
EOT
       )
  end

  def rule_exportHeader
    newRule('exportHeader')
    newPattern(%w( _export $STRING ), Proc.new {
      extension = @val[1][-4, 4]
      if extension != '.tjp' && extension != '.tji'
        error('export_bad_extn',
              'Export report files must have a .tjp or .tji extension.')
      end
      @report = ExportReport.new(@project, @val[1])
      @reportElement = @report.element
    })
    arg(1, 'filename', <<'EOT'
The name of the report file to generate. It must end with a .tjp or .tji
extension.
EOT
       )
  end

  def rule_exportAttributes
    newRule('exportAttributes')
    optional
    repeatable

    newPattern(%w( !hideresource ))
    newPattern(%w( !hidetask ))
    newPattern(%w( !reportEnd ))
    newPattern(%w( !reportPeriod ))
    newPattern(%w( !reportStart ))
  end

  def rule_exportBody
    newOptionsRule('exportBody', 'exportAttributes')
  end

  def rule_extendAttributes
    newRule('extendAttributes')
    optional
    repeatable

    newPattern(%w( _date !extendId  $STRING !extendOptionsBody ), Proc.new {
      # Extend the propertySet definition and parser rules
      if extendPropertySetDefinition(DateAttribute, nil)
        @ruleToExtendWithScenario.addPattern(TextParserPattern.new(
          [ '_' + @val[1], '$DATE' ], Proc.new {
            @property[@val[0], @scenarioIdx] = @val[1]
          }))
      else
        @ruleToExtend.addPattern(TextParserPattern.new(
          [ '_' + @val[1], '$DATE' ], Proc.new {
            @property.set(@val[0], @val[1])
          }))
      end
    })
    doc('extend.date', <<'EOT'
Extend the property with a new attribute of type date.
EOT
       )
    arg(2, 'name', 'The name of the new attribute. It is used as header ' +
                   'in report columns and the like.')

    newPattern(%w( _reference $STRING !extendOptionsBody ), Proc.new {
      # Extend the propertySet definition and parser rules
      reference = ReferenceAttribute.new
      reference.set([ @val[1], @val[2].nil? ? nil : @val[2][0] ])
      if extendPropertySetDefinition(ReferenceAttribute, nil)
        @ruleToExtendWithScenario.addPattern(TextParserPattern.new(
          [ '_' + @val[1], '$STRING', '!referenceBody' ], Proc.new {
            @property[@val[0], @scenarioIdx] = reference
          }))
      else
        @ruleToExtend.addPattern(TextParserPattern.new(
          [ '_' + @val[1], '$STRING', '!referenceBody' ], Proc.new {
            @property.set(reference)
          }))
      end
    })
    doc('extend.reference', <<'EOT'
Extend the property with a new attribute of type reference. A reference is a
URL and an optional text that will be shown instead of the URL if needed.
EOT
       )
    arg(2, 'name', 'The name of the new attribute. It is used as header ' +
                   'in report columns and the like.')

    newPattern(%w( _text !extendId $STRING !extendOptionsBody ), Proc.new {
      # Extend the propertySet definition and parser rules
      if extendPropertySetDefinition(StringAttribute, nil)
        @ruleToExtendWithScenario.addPattern(TextParserPattern.new(
          [ '_' + @val[1], '$STRING' ], Proc.new {
            @property[@val[0], @scenarioIdx] = @val[1]
          }))
      else
        @ruleToExtend.addPattern(TextParserPattern.new(
          [ '_' + @val[1], '$STRING' ], Proc.new {
            @property.set(@val[0], @val[1])
          }))
      end
    })
    doc('extend.text', <<'EOT'
Extend the property with a new attribute of type text. A text is a character
sequence enclosed in single or double quotes.
EOT
       )
    arg(2, 'name', 'The name of the new attribute. It is used as header ' +
                   'in report columns and the like.')

  end

  def rule_extendBody
    newOptionsRule('extendBody', 'extendAttributes')
  end

  def rule_extendId
    newRule('extendId')
    newPattern(%w( $ID ), Proc.new {
      unless (?A..?Z) === @val[0][0]
        error('extend_id_cap',
              "User defined attributes IDs must start with a capital letter")
      end
      @val[0]
    })
    arg(0, 'id', 'The ID of the new attribute. It can be used like the ' +
                 'built-in IDs.')
  end

  def rule_extendOptions
    newRule('extendOptions')
    optional
    repeatable

    singlePattern('_inherit')
    doc('extend.inherit', <<'EOT'
If the this attribute is used, the property extension will be inherited by
child properties from their parent property.
EOT
       )

    singlePattern('_scenariospecific')
    doc('extend.scenariospecific', <<'EOT'
If this attribute is used, the property extension is scenario specific. A
different value can be set for each scenario.
EOT
       )
  end

  def rule_extendOptionsBody
    newOptionsRule('extendOptionsBody', 'extendOptions')
  end

  def rule_extendProperty
    newRule('extendProperty')
    newPattern(%w( !extendPropertyId ), Proc.new {
      case @val[0]
      when 'task'
        @ruleToExtend = @rules['taskAttributes']
        @ruleToExtendWithScenario = @rules['taskScenarioAttributes']
        @propertySet = @project.tasks
      when 'resource'
        @ruleToExtend = @rules['resourceAttributes']
        @ruleToExtendWithScenario = @rules['resourceScenarioAttributes']
        @propertySet = @project.resources
      end
    })
  end

  def rule_extendPropertyId
    newRule('extendPropertyId')
    singlePattern('_task')
    singlePattern('_resource')
  end


  def rule_flag
    newRule('flag')
    newPattern(%w( $ID ), Proc.new {
      unless @project['flags'].include?(@val[0])
        error('undecl_flag', "Undeclared flag #{@val[0]}")
      end
      @val[0]
    })
  end

  def rule_flagList
    newListRule('flagList', '!flag')
  end

  def rule_hideresource
    newRule('hideresource')
    newPattern(%w( _hideresource !logicalExpression ), Proc.new {
      @reportElement.hideResource = @val[1]
    })
    doc('hideresource', <<'EOT'
Do not include resources that match the specified logical expression. If the
report is sorted in tree mode (default) then enclosing resources are listed
even if the expression matches the resource.
EOT
       )
  end

  def rule_hidetask
    newRule('hidetask')
    newPattern(%w( _hidetask !logicalExpression ), Proc.new {
      @reportElement.hideTask = @val[1]
    })
    doc('hidetask', <<'EOT'
Do not include tasks that match the specified logical expression. If the
report is sorted in tree mode (default) then enclosing tasks are listed even
if the expression matches the task.
EOT
       )
  end

  def rule_htmlResourceReport
    newRule('htmlResourceReport')
    newPattern(%w( !htmlResourceReportHeader !reportBody ))
    doc('htmlresourcereport', <<'EOT'
The report lists all resources and their respective values as a HTML page. The
task that are the resources are allocated to can be listed as well.
EOT
       )
  end

  def rule_htmlResourceReportHeader
    newRule('htmlResourceReportHeader')
    newPattern(%w( _htmlresourcereport $STRING ), Proc.new {
      @report = HTMLresourceReport.new(@project, @val[1])
      @reportElement = @report.element
    })
    arg(1, 'filename', <<'EOT'
The name of the report file to generate. It should end with a .html extension.
EOT
       )
  end

  def rule_htmlTaskReport
    newRule('htmlTaskReport')
    newPattern(%w( !htmlTaskReportHeader !reportBody ))
    doc('htmltaskreport', <<'EOT'
The report lists all tasks and their respective values as a HTML page. The
resources that are allocated to each task can be listed as well.
EOT
       )
  end

  def rule_htmlTaskReportHeader
    newRule('htmlTaskReportHeader')
    newPattern(%w( _htmltaskreport $STRING ), Proc.new {
      @report = HTMLTaskReport.new(@project, @val[1])
      @reportElement = @report.element
    })
    arg(1, 'filename', <<'EOT'
The name of the report file to generate. It should end with a .html extension.
EOT
       )
  end

  def rule_include
    newRule('include')
    newPattern(%w( _include $STRING ), Proc.new {
      @scanner.include(@val[1])
    })
    doc('include', <<'EOT'
Includes the specified file name as if its contents would be written
instead of the include property. The only exception is the include
statement itself. When the included files contains other include
statements or report definitions, the filenames are relative to file
where they are defined in. include commands can be used in the project
header, at global scope or between property declarations of tasks,
resources, and accounts.

For technical reasons you have to supply the optional pair of curly
brackets if the include is followed immediately by a macro call that
is defined within the included file.
EOT
       )
  end

  def rule_interval
    newRule('interval')
    newPattern(%w( $DATE !intervalEnd ), Proc.new {
      mode = @val[1][0]
      endSpec = @val[1][1]
      if mode == 0
        Interval.new(@val[0], endSpec)
      else
        Interval.new(@val[0], @val[0] + endSpec)
      end
    })
    arg(0, 'start date', 'The start date of the interval')
  end

  def rule_intervalDuration
    newRule('intervalDuration')
    newPattern(%w( $INTEGER !durationUnit ), Proc.new {
      convFactors = [ 60, # minutes
                      60 * 60, # hours
                      60 * 60 * 24, # days
                      60 * 60 * 24 * 7, # weeks
                      60 * 60 * 24 * 30.4167, # months
                      60 * 60 * 24 * 365 # years
                     ]
      (@val[0] * convFactors[@val[1]]).to_i
    })
    arg(0, 'duration', 'The duration of the interval')
  end

  def rule_intervalEnd
    newRule('intervalEnd')
    newPattern([ '_ - ', '$DATE' ], Proc.new {
      [ 0, @val[1] ]
    })
    arg(1, 'end date', 'The end date of the interval')

    newPattern(%w( _+ !intervalDuration ), Proc.new {
      [ 1, @val[1] ]
    })
  end

  def rule_intervals
    newListRule('intervals', '!interval')
  end

  def rule_listOfDays
    newRule('listOfDays')
    newPattern(%w( !weekDayInterval !moreListOfDays), Proc.new {
      weekDays = Array.new(7, false)
      ([ @val[0] ] + @val[1]).each do |dayList|
        0.upto(6) { |i| weekDays[i] = true if dayList[i] }
      end
      weekDays
    })
  end

  def rule_listOfTimes
    newRule('listOfTimes')
    newPattern(%w( _off ), Proc.new {
      [ ]
    })
    newPattern(%w( !timeInterval !moreTimeIntervals ), Proc.new {
      [ @val[0] ] + @val[1]
    })
  end

  def rule_logicalExpression
    newRule('logicalExpression')
    newPattern(%w( !operation ), Proc.new {
      LogicalExpression.new(@val[0], @scanner.fileName, @scanner.lineNo)
    })
    doc('logicalexpression', <<'EOT'
A logical expression consists of logical operations, such as '&' for and, '|'
for or, '~' for not, '>' for greater than, '<' for less than, '=' for equal,
'>=' for greater than or equal and '<=' for less than or equal to operate on
INTEGER values or symbols. Flag names and certain functions are supported as
symbols as well. The expression is evaluated from left to right. '~' has a
higher precedence than other operators. Use parentheses to avoid ambiguous
operations.
EOT
       )
  end

  def rule_macro
    newRule('macro')
    newPattern(%w( _macro $ID $MACRO ), Proc.new {
      @scanner.addMacro(Macro.new(@val[1], @val[2], @scanner.sourceFileInfo))
    })
  end

  def rule_moreAlternatives
    newCommaListRule('moreAlternatives', '!resourceId')
  end

  def rule_moreArguments
    newCommaListRule('moreArguments', '!operation')
  end

  def rule_moreColumnDef
    newCommaListRule('moreColumnDef', '!columnDef')
  end

  def rule_moreDepTasks
    newCommaListRule('moreDepTasks', '!taskDep')
  end

  def rule_moreListOfDays
    newCommaListRule('moreListOfDays', '!weekDayInterval')
  end

  def rule_moreResources
    newCommaListRule('moreResources', '!resourceList')
  end

  def rule_morePrevTasks
    newCommaListRule('morePredTasks', '!taskPredList')
  end

  def rule_moreTimeIntervals
    newCommaListRule('moreTimeIntervals', '!timeInterval')
  end

  def rule_number
    newRule('number')
    singlePattern('$INTEGER')
    singlePattern('$FLOAT')
  end

  def rule_operand
    newRule('operand')
    newPattern(%w( _( !operation _) ), Proc.new {
      @val[1]
    })
    newPattern(%w( _~ !operand ), Proc.new {
      operation = LogicalOperation.new(@val[1])
      operation.operator = '~'
      operation
    })

    newPattern(%w( $ABSOLUTE_ID ), Proc.new {
      if @val[0].count('.') > 1
        error('operand_attribute',
              'Attributes must be specified as <scenarioID>.<attribute>')
      end
      scenario, attribute = @val[0].split('.')
      if (scenarioIdx = @project.scenarioIdx(scenario)).nil?
        error('operand_unkn_scen',
              "Unknown scenario ID #{scenario}")
      end
      LogicalAttribute.new(attribute, scenarioIdx)
    })
    newPattern(%w( $DATE ), Proc.new {
      LogicalOperation.new(@val[0])
    })
    newPattern(%w( $ID !argumentList ), Proc.new {
      if @val[1].nil?
        unless @project['flags'].include?(@val[0])
          error('operand_unkn_flag', "Undeclared flag #{@val[0]}")
        end
        operation = LogicalFlag.new(@val[0])
      else
        # TODO: add support for old functions
      end
    })
    newPattern(%w( $INTEGER ), Proc.new {
      LogicalOperation.new(@val[0])
    })
    newPattern(%w( $STRING ), Proc.new {
      LogicalOperation.new(@val[0])
    })
  end

  def rule_operation
    newRule('operation')
    newPattern(%w( !operand !operatorAndOperand ), Proc.new {
      operation = LogicalOperation.new(@val[0])
      unless @val[1].nil?
        operation.operator = @val[1][0]
        operation.operand2 = @val[1][1]
      end
      operation
    })
    arg(0, 'operand', <<'EOT'
An operand can consist of a date, a text string or a numerical value. It can also be the name of a declared flag. Finally, an operand can be a negated operand by prefixing a ~ charater or it can be another operation enclosed in braces.
EOT
        )

  end

  def rule_operatorAndOperand
    newRule('operatorAndOperand')
    optional
    newPattern(%w( !operator !operand), Proc.new{
      [ @val[0], @val[1] ]
    })
    arg(1, 'operand', <<'EOT'
An operand can consist of a date, a text string or a numerical value. It can also be the name of a declared flag. Finally, an operand can be a negated operand by prefixing a ~ charater or it can be another operation enclosed in braces.
EOT
        )
  end

  def rule_operator
    newRule('operator')

    singlePattern('_|')
    descr('The \'or\' operator')

    singlePattern('_&')
    descr('The \'and\' operator')

    singlePattern('_>')
    descr('The \'greater than\' operator')

    singlePattern('_<')
    descr('The \'smaller than\' operator')

    singlePattern('_=')
    descr('The \'equal\' operator')

    singlePattern('_>=')
    descr('The \'greater-or-equal\' operator')

    singlePattern('_<=')
    descr('The \'smaller-or-equal\' operator')
  end

  def rule_period
    newRule('period')
    newPattern(%w( _period !valInterval), Proc.new {
      @property['start', @scenarioIdx] = @val[1].start
      @property['end', @scenarioIdx] = @val[1].end
    })
    doc('period', <<'EOT'
This property is a shortcut for setting the start and end property at the same
time. In contrast to using these, it does not change the scheduling direction. The full period must be within the report time frame.
EOT
       )
  end


  def rule_project
    newRule('project')
    newPattern(%w( !projectDeclaration !properties ), Proc.new {
      @val[0]
    })
    newPattern(%w( !macro ))
  end

  def rule_projectBody
    newOptionsRule('projectBody', 'projectBodyAttributes')
  end

  def rule_projectBodyAttributes
    newRule('projectBodyAttributes')
    repeatable
    optional

    newPattern(%w( _currencyformat $STRING $STRING $STRING $STRING $STRING ),
        Proc.new {
      @project['currencyformat'] = RealFormat.new(@val.slice(1, 5))
    })
    doc('currencyformat',
        'These values specify the default format used for all currency ' +
        'values.')
    arg(1, 'negativeprefix', 'Prefix for negative numbers')
    arg(2, 'negativesuffix', 'Suffix for negative numbers')
    arg(3, 'thousandsep', 'Separator used for every 3rd digit')
    arg(4, 'fractionsep', 'Separator used to separate the fraction digits')
    arg(5, 'fractiondigits', 'Number of fraction digits to show')

    newPattern(%w( _currency $STRING ), Proc.new {
      @project['currency'] = @val[1]
    })
    doc('currency', 'The default currency unit.')
    arg(1, 'symbol', 'Currency symbol')

    newPattern(%w( _dailyworkinghours !number ), Proc.new {
      @project['dailyworkinghours'] = @val[1]
    })
    doc('dailyworkinghours', <<'EOT'
Set the average number of working hours per day. This is used as
the base to convert working hours into working days. This affects
for example the length task attribute. The default value is 8 hours
and should work for most Western countries. The value you specify
should match the settings you specified for workinghours.
EOT
       )
    arg(1, 'hours', 'Average number of working hours per working day')

    newPattern(%w( _extend !extendProperty !extendBody ), Proc.new {
      updateParserTables
    })
    doc('extend', <<'EOT'
Often it is desirable to collect more information in the project file than is
necessary for task scheduling and resource allocation. To add such information
to tasks, resources or accounts the user can extend these properties with
user-defined attributes. The new attributes can be of various types such as
text, date or reference to capture various types of data. Optionally the user
can specify if the attribute value should be inherited from the enclosing
property.
EOT
       )

    newPattern(%w( !include ))

    newPattern(%w( _now $DATE ), Proc.new {
      @project['now'] = @val[1]
      @scanner.addMacro(Macro.new('now', @val[1].to_s,
                                  @scanner.sourceFileInfo))
    })
    doc('now', <<'EOT'
Specify the date that TaskJuggler uses for calculation as current
date. If no value is specified, the current value of the system
clock is used.
EOT
       )
    arg(1, 'date', 'Alternative date to be used as current date for all ' +
        'computations')

    newPattern(%w( _numberformat $STRING $STRING $STRING $STRING $STRING ),
        Proc.new {
      @project['numberformat'] = RealFormat.new(@val.slice(1, 5))
    })
    doc('numberformat',
        'These values specify the default format used for all numerical ' +
        'real values.')
    arg(1, 'negativeprefix', 'Prefix for negative numbers')
    arg(2, 'negativesuffix', 'Suffix for negative numbers')
    arg(3, 'thousandsep', 'Separator used for every 3rd digit')
    arg(4, 'fractionsep', 'Separator used to separate the fraction digits')
    arg(5, 'fractiondigits', 'Number of fraction digits to show')

    newPattern(%w( !scenario ))
    newPattern(%w( _shorttimeformat $STRING ), Proc.new {
      @project['shorttimeformat'] = @val[1]
    })
    doc('shorttimeformat',
        'Specifies time format for time short specifications. This is normal' +
        'just the hour and minutes.')
    arg(1, 'format', 'strftime like format string')

    newPattern(%w( _timeformat $STRING ), Proc.new {
      @project['timeformat'] = @val[1]
    })
    doc('timeformat',
        'Determines how time specifications in reports look like.')
    arg(1, 'format', 'strftime like format string')

    newPattern(%w( !timezone ), Proc.new {
      @project['timezone'] = @val[1]
    })

    newPattern(%w( _timingresolution $INTEGER _min ), Proc.new {
      error('min_timing_res',
            'Timing resolution must be at least 5 min.') if @val[1] < 5
      error('max_timing_res',
            'Timing resolution must be 1 hour or less.') if @val[1] > 60
      @project['scheduleGranularity'] = @val[1]
    })
    doc('timingresolution', <<'EOT'
Sets the minimum timing resolution. The smaller the value, the longer the
scheduling process lasts and the more memory the application needs. The
default and maximum value is 1 hour. The smallest value is 5 min.
This value is a pretty fundamental setting of TaskJuggler. It has a severe
impact on memory usage and scheduling performance. You should set this value
to the minimum required resolution. Make sure that all values that you specify
are aligned with the resolution.

The timing resolution should be set prior to any value that represents a time
value like now or workinghours.
EOT
        )
    arg(1, 'resolution', 'The minimum interval that the scheduler uses to ' +
        'align tasks')

    newPattern(%w( _weekstartsmonday ), Proc.new {
      @project['weekstartsmonday'] = true
    })
    doc('weekstartsmonday',
        'Specify that you want to base all week calculation on weeks ' +
        'starting on Monday. This is common in many European countries.')

    newPattern(%w( _weekstartssunday ), Proc.new {
      @project['weekstartsmonday'] = false
    })
    doc('weekstartssunday',
        'Specify that you want to base all week calculation on weeks ' +
        'starting on Sunday. This is common in the United States of America.')

    newPattern(%w( _yearlyworkingdays !number ), Proc.new {
      @project['yearlyworkingdays'] = @val[1]
    })
    doc('yearlyworkingdays', <<'EOT'
Specifies the number of average working days per year. This should correlate
to the specified workinghours and vacation. It affects the conversion of
working hours, working days, working weeks, working months and working years
into each other.

When public holidays and vacations are disregarded, this value should be equal
to the number of working days per week times 52.1428 (the average number of
weeks per year). E. g. for a culture with 5 working days it is 260.714 (the
default), for 6 working days it is 312.8568 and for 7 working days it is
365.
EOT
       )
    arg(1, 'days', 'Number of average working days for a year')
  end

  def rule_projectDeclaration
    newRule('projectDeclaration')
    newPattern(%w( !projectHeader !projectBody ), Proc.new {
      @val[0]
    })
    doc('project', <<'EOT'
The project property is mandatory and should be the first property
in a project file. It is used to capture basic attributes such as
the project id, name and the expected time frame.
EOT
       )
  end

  def rule_projectHeader
    newRule('projectHeader')
    newPattern(%w( _project $ID $STRING $STRING !interval ), Proc.new {
      @project = Project.new(@val[1], @val[2], @val[3], @messageHandler)
      @project['start'] = @val[4].start
      @scanner.addMacro(Macro.new('projectstart', @project['start'].to_s,
                                  @scanner.sourceFileInfo))
      @project['end'] = @val[4].end
      @scanner.addMacro(Macro.new('projectend', @project['end'].to_s,
                                  @scanner.sourceFileInfo))
      @scanner.addMacro(Macro.new('now', TjTime.now.to_s,
                                  @scanner.sourceFileInfo))
      @property = nil
      @project
    })
    arg(1, 'id', 'The ID of the project')
    arg(2, 'name', 'The name of the project')
    arg(3, 'version', 'The version of the project plan')
  end

  def rule_projection
    newOptionsRule('projection', 'projectionAttributes')
  end

  def rule_projectionAttributes
    newRule('projectionAttributes')
    optional
    repeatable
    newPattern(%w( _sloppy ), Proc.new {
      @property['strict', @scenarioIdx] = false
    })
    doc('projection.sloppy', <<'EOT'
In sloppy mode tasks with no bookings will be filled from the original start.
EOT
       )

    newPattern(%w( _strict ), Proc.new {
      @property['strict', @scenarioIdx] = true
    })
    doc('projection.strict', <<'EOT'
In strict mode all tasks will be filled starting with the current date. No
bookings will be added prior to the current date.
EOT
       )
  end

  def rule_properties
    newRule('properties')
    repeatable
    newPattern(%w( _copyright $STRING ), Proc.new {
      @project['copyright'] = @val[1]
    })
    newPattern(%w( !export ))
    newPattern(%w( _flags !declareFlagList ), Proc.new {
      unless @project['flags'].include?(@val[1])
        @project['flags'] += @val[1]
      end
    })
    newPattern(%w( !htmlResourceReport ))
    newPattern(%w( !htmlTaskReport ))
    newPattern(%w( !include ))
    newPattern(%w( !macro ))
    newPattern(%w( !resource ))
    newPattern(%w( _supplement !supplement ))
    newPattern(%w( !task ))
    newPattern(%w( _vacation !vacationName !intervals ), Proc.new {
      @project['vacations'] = @project['vacations'] + @val[2]
    })
    newPattern(%w( !workinghours ))
  end

  def rule_referenceAttributes
    newRule('referenceAttributes')
    optional
    repeatable
    newPattern(%w( _label $STRING ), Proc.new {
      @val[1]
    })
  end

  def rule_referenceBody
    newOptionsRule('referenceBody', 'referenceAttributes')
  end

  def rule_reportAttributes
    newRule('reportAttributes')
    optional
    repeatable

    newPattern(%w( _columns !columnDef !moreColumnDef ), Proc.new {
      columns = [ @val[1] ]
      columns += @val[2] if @val[2]
      @reportElement.columns = columns
    })
    doc('columns', <<'EOT'
Specifies which columns shall be included in a report.

All columns support macro expansion. Contrary to the normal macro expansion,
these macros are expanded during the report generation. So the value of the
macro is being changed after each table cell or table line. Consequently only
build in macros can be used. To protect the macro calls against expansion
during the initial file processing, the report macros must be prefixed with an
additional $.
EOT
       )

    newPattern(%w( !reportEnd ))

    newPattern(%w( _headline $STRING ), Proc.new {
      @reportElement.headline = @val[1]
    })
    doc('headline', <<'EOT'
Specifies the headline for a report.
EOT
       )

    newPattern(%w( !hideresource ))

    newPattern(%w( !hidetask ))

    newPattern(%w( !reportPeriod ))

    newPattern(%w( _rolluptask !logicalExpression ), Proc.new {
      @reportElement.rollupTask = @val[1]
    })
    doc('rolluptask', <<'EOT'
Do not show sub-tasks of tasks that match the specified logical expression.
EOT
       )

    newPattern(%w( _scenarios !scenarioIdList ), Proc.new {
      # Don't include disabled scenarios in the report
      @val[1].delete_if { |sc| !@project.scenario(sc).get('enabled') }
      @reportElement.scenarios = @val[1]
    })
    doc('scenrios', <<'EOT'
List of scenarios that should be included in the report.
EOT
       )

    newPattern(%w( _sortresources !sortCriteria ), Proc.new {
      @reportElement.sortResources = @val[1]
    })
    doc('sortresources', <<'EOT'
Determines how the resources are sorted in the report. Multiple criteria can be
specified as a comma separated list. If one criteria is not sufficient to sort
a group of resources, the next criteria will be used to sort the resources in
this group.
EOT
       )

    newPattern(%w( _sorttasks !sortCriteria ), Proc.new {
      @reportElement.sortTasks = @val[1]
    })
    doc('sorttasks', <<'EOT'
Determines how the tasks are sorted in the report. Multiple criteria can be
specified as comma separated list. If one criteria is not sufficient to sort a
group of tasks, the next criteria will be used to sort the tasks within
this group.
EOT
       )

    newPattern(%w( !reportStart ))

    newPattern(%w( _taskroot !taskId), Proc.new {
      @reportElement.taskRoot = @val[1]
    })
    doc('taskroot', <<'EOT'
Only tasks below the specified root-level tasks are exported. The exported
tasks will have the id of the root-level task stripped from their ID, so that
the sub-tasks of the root-level task become top-level tasks in the exported
file.
EOT
       )

    newPattern(%w( _timeformat $STRING ), Proc.new {
      @reportElement.timeformat = @val[1]
    })
    doc('report.timeformat', <<'EOT'
Determines how time specifications in reports look like.
EOT
       )
    arg(1, 'format', <<'EOT'
Ordinary characters placed in the format string are copied without
conversion. Conversion specifiers are introduced by a `%' character, and are
replaced in s as follows:

%a  The abbreviated weekday name according to the current locale.

%A  The full weekday name according to the current locale.

%b  The abbreviated month name according to the current locale.

%B  The full month name according to the current locale.

%c  The preferred date and time representation for the current locale.

%C  The century number (year/100) as a 2-digit integer. (SU)

%d  The day of the month as a decimal number (range 01 to 31).

%e  Like %d, the day of the month as a decimal number, but a leading zero is
replaced by a space. (SU)

%E  Modifier: use alternative format, see below. (SU)

%F  Equivalent to %Y-%m-%d (the ISO 8601 date format). (C99)

%G  The ISO 8601 year with century as a decimal number. The 4-digit year
corresponding to the ISO week number (see %V). This has the same format and
value as %y, except that if the ISO week number belongs to the previous or next
year, that year is used instead. (TZ)

%g  Like %G, but without century, i.e., with a 2-digit year (00-99). (TZ)

%h  Equivalent to %b. (SU)

%H  The hour as a decimal number using a 24-hour clock (range 00 to 23).

%I  The hour as a decimal number using a 12-hour clock (range 01 to 12).

%j  The day of the year as a decimal number (range 001 to 366).

%k  The hour (24-hour clock) as a decimal number (range 0 to 23); single digits
are preceded by a blank. (See also %H.) (TZ)

%l  The hour (12-hour clock) as a decimal number (range 1 to 12); single digits
are preceded by a blank. (See also %I.) (TZ)

%m  The month as a decimal number (range 01 to 12).

%M  The minute as a decimal number (range 00 to 59).

%n  A newline character. (SU)

%O  Modifier: use alternative format, see below. (SU)

%p  Either 'AM' or 'PM' according to the given time value, or the corresponding
strings for the current locale. Noon is treated as `pm' and midnight as 'am'.

%P  Like %p but in lowercase: 'am' or 'pm' or %a corresponding string for the
current locale. (GNU)

%r  The time in a.m. or p.m. notation. In the POSIX locale this is equivalent
to '%I:%M:%S %p'. (SU)

%R  The time in 24-hour notation (%H:%M). (SU) For a version including the
seconds, see %T below.

%s  The number of seconds since the Epoch, i.e., since 1970-01-01 00:00:00 UTC.
(TZ)

%S  The second as a decimal number (range 00 to 61).

%t  A tab character. (SU)

%T  The time in 24-hour notation (%H:%M:%S). (SU)

%u  The day of the week as a decimal, range 1 to 7, Monday being 1. See also
%w. (SU)

%U  The week number of the current year as a decimal number, range 00 to 53,
starting with the first Sunday as the first day of week 01. See also %V and %W.

%V  The ISO 8601:1988 week number of the current year as a decimal number,
range 01 to 53, where week 1 is the first week that has at least 4 days in the
current year, and with Monday as the first day of the week. See also %U %and
%W. %(SU)

%w  The day of the week as a decimal, range 0 to 6, Sunday being 0. See also %u.

%W  The week number of the current %year as a decimal number, range 00 to 53,
starting with the first Monday as the first day of week 01.

%x  The preferred date representation for the current locale without the time.

%X  The preferred time representation for the current locale without the date.

%y  The year as a decimal number without a century (range 00 to 99).

%Y   The year as a decimal number including the century.

%z   The time zone as hour offset from GMT. Required to emit RFC822-conformant
dates (using "%a, %d %%b %Y %H:%M:%S %%z"). (GNU)

%Z  The time zone or name or abbreviation.

%+  The date and time in date(1) format. (TZ)

%%  A literal '%' character.

Some conversion specifiers can be modified by preceding them by the E or O
modifier to indicate that an alternative format should be used. If the
alternative format or specification does not exist for the current locale, the
behavior will be as if the unmodified conversion specification were used. (SU)
The Single Unix Specification mentions %Ec, %EC, %Ex, %%EX, %Ry, %EY, %Od, %Oe,
%OH, %OI, %Om, %OM, %OS, %Ou, %OU, %OV, %Ow, %OW, %Oy, where the effect of the
O modifier is to use alternative numeric symbols (say, Roman numerals), and
that of the E modifier is to use a locale-dependent alternative representation.
The documentation of the timeformat attribute has been taken from the man page
of the GNU strftime function.
EOT
       )
  end

  def rule_reportableAttributes
    newRule('reportableAttributes')

    singlePattern('_complete')
    descr('The completion degree of a task')

    singlePattern('_criticalness')
    descr('A measure for how much effort the resource is allocated for, or' +
          'how strained the allocated resources of a task are')

    singlePattern('_daily')
    descr('A group of columns with one column for each day')

    singlePattern('_duration')
    descr('The duration of a task')

    singlePattern('_duties')
    descr('List of tasks that the resource is allocated to')

    singlePattern('_efficiency')
    descr('Measure for how efficient a resource can perform tasks')

    singlePattern('_effort')
    descr('The total allocated effort')

    singlePattern('_email')
    descr('The email address of a resource')

    singlePattern('_end')
    descr('The end date of a task')

    singlePattern('_flags')
    descr('List of attached flags')

    singlePattern('_fte')
    descr('The Full-Time-Equivalent of a resource or group')

    singlePattern('_headcount')
    descr('The headcount number of the resource or group')

    singlePattern('_hourly')
    descr('A group of columns with one column for each hour')

    singlePattern('_index')
    descr('The index of the item based on the nesting hierachy')

    singlePattern('_maxend')
    descr('The latest allowed end of a task')

    singlePattern('_maxstart')
    descr('The lastest allowed start of a task')

    singlePattern('_minend')
    descr('The earliest allowed end of a task')

    singlePattern('_minstart')
    descr('The earliest allowed start of a task')

    singlePattern('_monthly')
    descr('A group of columns with one column for each month')

    singlePattern('_no')
    descr('The index in the report')

    singlePattern('_name')
    descr('The name or description of the item')

    singlePattern('_pathcriticalness')
    descr('The criticalness of the task with respect to all the paths that ' +
          'it is a part of.')

    singlePattern('_priority')
    descr('The priority of a task')

    singlePattern('_quarterly')
    descr('A group of columns with one column for each quarter')

    singlePattern('_responsible')
    descr('The responsible people for this task')

    singlePattern('_seqno')
    descr('The index of the item based on the declaration order')

    singlePattern('_start')
    descr('The start date of the task')

    singlePattern('_wbs')
    descr('The hierarchical or work breakdown structure index')

    singlePattern('_weekly')
    descr('A group of columns with one column for each week')

    singlePattern('_yearly')
    descr('A group of columns with one column for each year')

  end

  def rule_reportBody
    newOptionsRule('reportBody', 'reportAttributes')
  end

  def rule_report_end
    newRule('reportEnd')
    newPattern(%w( _end !valDate ), Proc.new {
      @reportElement.end = @val[1]
    })
    doc('report.end', <<'EOT'
Specifies the end date of the report. In task reports only tasks that start
before this end date are listed.
EOT
       )
  end

  def rule_reportPeriod
    newRule('reportPeriod')
    newPattern(%w( _period !interval ), Proc.new {
      @reportElement.start = @val[1].start
      @reportElement.end = @val[1].end
    })
    doc('report.period', <<'EOT'
This property is a shortcut for setting the start and end property at the
same time.
EOT
       )
  end

  def rule_reportStart
    newRule('reportStart')
    newPattern(%w( _start !valDate ), Proc.new {
      @reportElement.start = @val[1]
    })
    doc('report.start', <<'EOT'
Specifies the start date of the report. In task reports only tasks that end
after this end date are listed.
EOT
       )
  end

  def rule_resource
    newRule('resource')
    newPattern(%w( !resourceHeader !resourceBody ), Proc.new {
       @property = @property.parent
    })
    doc('resource', <<'EOT'
Tasks that have an effort specification need to have resources assigned to do
the work. Use this property to define resources or group of resources.
EOT
       )
  end

  def rule_resourceAllocation
    newRule('resourceAllocation')
    newPattern(%w( !resourceId !allocationAttributes ), Proc.new {
      candidates = [ @val[0] ]
      selectionMode = 1 # Defaults to min. allocation probability
      mandatory = false
      persistant = false
      if @val[1]
        @val[1].each do |attribute|
          case attribute[0]
          when 'alternative'
            candidates += attribute[1]
          when 'persistant'
            persistant = true
          when 'mandatory'
            mandatory = true
          end
        end
      end
      Allocation.new(candidates, selectionMode, persistant, mandatory)
    })
    doc('allocate.resources', <<'EOT'
The optional attributes provide numerous ways to control which resource is
used and when exactly it will be assigned to the task. Shifts and limits can
be used to restrict the allocation to certain time intervals or to limit them
to a certain maximum per time period.
EOT
       )
    arg(0, 'resource', 'A resource ID')
  end

  def rule_resourceAllocations
    newListRule('resourceAllocations', '!resourceAllocation')
  end

  def rule_resourceAttributes
    newRule('resourceAttributes')
    repeatable
    optional
    newPattern(%w( !resource ))
    newPattern(%w( !resourceScenarioAttributes ))
    newPattern(%w( !scenarioId !resourceScenarioAttributes ), Proc.new {
      @scenarioIdx = 0
    })
    # Other attributes will be added automatically.
  end

  def rule_resourceBody
    newOptionsRule('resourceBody', 'resourceAttributes')
  end

  def rule_resourceBooking
    newRule('resourceBooking')
    newPattern(%w( !resourceBookingHeader !bookingBody ), Proc.new {
      @val[0].task.addBooking(@scenarioIdx, @val[0])
    })
  end

  def rule_resourceBookingHeader
    newRule('resourceBookingHeader')
    newPattern(%w( !taskId !intervals ), Proc.new {
      @booking = Booking.new(@property, @val[0], @val[1])
      @booking.sourceFileInfo = @scanner.sourceFileInfo
      @booking
    })
    arg(0, 'id', 'Absolute ID of a defined task')
  end

  def rule_resourceId
    newRule('resourceId')
    newPattern(%w( $ID ), Proc.new {
      if (resource = @project.resource(@val[0])).nil?
        error('resource_id_expct', "Resource ID expected")
      end
      resource
    })
    arg(0, 'resource', 'The ID of a defined resource')
  end

  def rule_resourceHeader
    newRule('resourceHeader')
    newPattern(%w( _resource $ID $STRING ), Proc.new {
      @property = Resource.new(@project, @val[1], @val[2], @property)
      @property.inheritAttributes
    })
    arg(1, 'id', <<'EOT'
The ID of the resource. Resources have a global name space. The ID must be
unique within the whole project.
EOT
       )
    arg(2, 'name', 'The name of the resource')
  end

  def rule_resourceList
    newRule('resourceList')
    newPattern(%w( !resourceId !moreResources ), Proc.new {
      [ @val[0] ] + @val[1]
    })
  end

  def rule_resourceScenarioAttributes
    newRule('resourceScenarioAttributes')

    newPattern(%w( _flags !flagList ), Proc.new {
      @property['flags', @scenarioIdx] += @val[1]
    })
    doc('resource.flags', <<'EOT'
Attach a set of flags. The flags can be used in logical expressions to filter
properties from the reports.
EOT
       )

    newPattern(%w( _booking !resourceBooking ))
    doc('booking', <<'EOT'
The booking attribute can be used to report completed work. This can be part
of the necessary effort or the whole effort. When the scenario is scheduled in
projection mode, TaskJuggler assumes that only the work reported with bookings
has been done up to now. It then schedules a plan for the still missing
effort.

This attribute is also used within export reports to describe the details of a
scheduled project.

The sloppy attribute can be used when you want to skip non-working time or
other allocations automatically. If it's not given, all bookings must only
cover working time for the resource.
EOT
       )

    newPattern(%w( _vacation !vacationName !intervals ), Proc.new {
      @property['vacations', @scenarioIdx] =
        @property['vacations', @scenarioIdx ] + @val[2]
    })
    doc('resource.vacation', <<'EOT'
Specify a vacation period for the resource. It can also be used to block out
the time before a resource joint or after it left. For employees changing
their work schedule from full-time to part-time, or vice versa, please refer
to the 'Shift' property.
EOT
       )

    newPattern(%w( !workinghours ))
    # Other attributes will be added automatically.
  end

  def rule_scenario
    newRule('scenario')
    newPattern(%w( !scenarioHeader !scenarioBody ), Proc.new {
      @property = @property.parent
    })
    doc('scenario', <<'EOT'
Specifies the different project scenarios. A scenario that is nested into
another one inherits all inheritable values from the enclosing scenario. There
can only be one top-level scenario. It is usually called plan scenario. By
default this scenario is pre-defined but can be overwritten with any other
scenario. In this documenation each attribute is listed as scenario specific
or not. A scenario specific attribute can be overwritten in a child scenario
thereby creating a new, slightly different variant of the parent scenario.
This can be helpful to do plan/actual comparisons if what-if-anlysises.

By using bookings and enabling the projection mode you can capture the
progress of your project and constantly get updated project plans for the
future work.
EOT
       )
  end

  def rule_scenarioAttributes
    newRule('scenarioAttributes')
    optional
    repeatable

    newPattern(%w( _projection !projection ), Proc.new {
      @property.set('projection', true)
    })
    doc('projection', <<'EOT'
Enables the projection mode for the scenario. All tasks will be scheduled
taking the manual bookings into account. The tasks will be extended by
scheduling new bookings starting with the current date until the specified
effort, length or duration has been reached.
EOT
       )

    newPattern(%w( !scenario ))
  end

  def rule_scenarioBody
    newOptionsRule('scenarioBody', 'scenarioAttributes')
  end

  def rule_scenarioHeader
    newRule('scenarioHeader')

    newPattern(%w( _scenario $ID $STRING ), Proc.new {
      # If this is the top-level scenario, we must delete the default scenario
      # first.
      @project.scenarios.clearProperties if @property.nil?
      @property = Scenario.new(@project, @val[1], @val[2], @property)
    })
    arg(1, 'id', 'The ID of the scenario')
    arg(2, 'name', 'The name of the scenario')
  end

  def rule_scenarioId
    newRule('scenarioId')
    newPattern(%w( $ID_WITH_COLON ), Proc.new {
      if (@scenarioIdx = @project.scenarioIdx(@val[0])).nil?
        error('unknown_scenario_id', "Unknown scenario: @val[0]")
      end
    })
  end

  def rule_scenarioIdList
    newListRule('scenarioIdList', '!scenarioIdx')
  end

  def rule_scenarioIdx
    newRule('scenarioIdx')
    newPattern(%w( $ID ), Proc.new {
      if (scenarioIdx = @project.scenarioIdx(@val[0])).nil?
        error('unknown_scenario_idx', "Unknown scenario #{@val[1]}")
      end
      scenarioIdx
    })
  end

  def rule_schedulingDirection
    newRule('schedulingDirection')
    singlePattern('_alap')
    singlePattern('_asap')
  end

  def rule_sortCriteria
    newListRule('sortCriteria', '!sortCriterium')
  end

  def rule_sortCriterium
    newRule('sortCriterium')
    newPattern(%w( $ABSOLUTE_ID ), Proc.new {
      args = @val[0].split('.')
      case args.length
      when 2
        scenario = -1
        direction = args[1]
        attribute = args[0]
      when 3
        if (scenario = @project.scenarioIdx(args[0])).nil?
          error('sort_unknown_scen',
                "Unknown scenario #{args[0]} in sorting criterium")
        end
        attribute = args[1]
        if args[2] != 'up' && args[2] != 'down'
          error('sort_direction', "Sorting direction must be 'up' or 'down'")
        end
        direction = args[2] == 'up'
      else
        error('sorting_crit_exptd1',
              "Sorting criterium expected (e.g. tree, start.up or " +
              "plan.end.down).")
      end
      [ attribute, direction, scenario ]
    })
    newPattern(%w( $ID ), Proc.new {
      if @val[0] != 'tree'
        error('sorting_crit_exptd2',
              "Sorting criterium expected (e.g. tree, start.up or " +
              "plan.end.down).")
      end
      [ 'tree', true, -1 ]
    })
  end

  def rule_supplement
    newRule('supplement')
    newPattern(%w( !supplementResource !resourceBody ))
    newPattern(%w( !supplementTask !taskBody ))
  end

  def rule_supplementResource
    newRule('supplementResource')
    newPattern(%w( _resource !resourceId ), Proc.new {
      @property = @val[1]
    })
  end

  def rule_supplementTask
    newRule('supplementTask')
    newPattern(%w( _task !taskId ), Proc.new {
      @property = @val[1]
    })
  end

  def rule_task
    newRule('task')

    newPattern(%w( !taskHeader !taskBody ), Proc.new {
      @property = @property.parent
    })
    doc('task', <<'EOT'
Tasks are the central elements of a project plan. Use a task to specify the
various steps and phases of the project. Depending on the attributes of that
task, a task can be a container task, a milestone or a regular leaf task. The
latter may have resources assigned. By specifying dependencies the user can
force a certain sequence of tasks.
EOT
       )
  end

  def rule_taskAttributes
    newRule('taskAttributes')
    repeatable
    optional
    newPattern(%w( _note $STRING ), Proc.new {
      @property.set('note', @val[1])
    })
    doc('task.note', <<'EOT'
Attach a note to the task. This is usually a more detailed specification of
what the task is about.
EOT
       )

    newPattern(%w( !task ))
    newPattern(%w( !taskScenarioAttributes ))
    newPattern(%w( !scenarioId !taskScenarioAttributes ), Proc.new {
      @scenarioIdx = 0
    })
    # Other attributes will be added automatically.
  end

  def rule_taskBody
    newOptionsRule('taskBody', 'taskAttributes')
  end

  def rule_taskBooking
    newRule('taskBooking')
    newPattern(%w( !taskBookingHeader !bookingBody ), Proc.new {
      @val[0].task.addBooking(@scenarioIdx, @val[0])
    })
  end

  def rule_taskBookingHeader
    newRule('taskBookingHeader')
    newPattern(%w( !resourceId !intervals ), Proc.new {
      @booking = Booking.new(@val[0], @property, @val[1])
      @booking.sourceFileInfo = @scanner.sourceFileInfo
      @booking
    })
  end

  def rule_taskDep
    newRule('taskDep')
    newPattern(%w( !taskDepHeader !taskDepBody ), Proc.new {
      @val[0]
    })
    doc('taskreference', <<'EOT'
Reference to another task.
EOT
       )
    arg(0, 'id', <<'EOT'
Absolute or relative ID of a task. An absolute task ID is a string of all
parent task IDs concatenated with dots. A relate ID starts with one or more
bangs. Each bang moves the scope to find the task with the specified ID to the
parent of the current task.
EOT
       )
  end

  def rule_taskDepAttributes
    newRule('taskDepAttributes')
    optional
    repeatable

    newPattern(%w( _gapduration !intervalDuration ), Proc.new {
      @taskDependency.gapDuration = @val[1]
    })
    doc('gapduration', <<'EOT'
Specifies the minimum required gap between the end of a preceding task and the
start of this task, or the start of a following task and the end of this task.
This is calendar time, not working time. 7d means one week.
EOT
       )

    newPattern(%w( _gaplength !workingDuration ), Proc.new {
      @taskDependency.gapLength = @val[1]
    })
    doc('gaplength', <<'EOT'
Specifies the minimum required gap between the end of a preceding task and the
start of this task, or the start of a following task and the end of this task.
This is working time, not calendar time. 7d means 7 working days, not one
week. Whether a day is considered a working day or not depends on the defined
working hours and global vacations.
EOT
       )

    newPattern(%w( _onend ), Proc.new {
      @taskDependency.onEnd = true
    })
    doc('onend', <<'EOT'
The target of the dependency is the end of the task.
EOT
       )

    newPattern(%w( _onstart ), Proc.new {
      @taskDependency.onEnd = false
    })
    doc('onstart', <<'EOT'
The target of the dependency is the start of the task.
EOT
       )
  end

  def rule_taskDepBody
    newOptionsRule('taskDepBody', 'taskDepAttributes')
  end

  def rule_taskDepHeader
    newRule('taskDepHeader')
    newPattern(%w( !taskDepId ), Proc.new {
      @taskDependency = TaskDependency.new(@val[0], true)
    })
  end

  def rule_taskDepId
    newRule('taskDepId')
    singlePattern('$ABSOLUTE_ID')
    singlePattern('$ID')
    newPattern(%w( $RELATIVE_ID ), Proc.new {
      task = @property
      id = @val[0]
      while task && id[0] == ?!
        id = id.slice(1, id.length)
        task = task.parent
      end
      error('too_many_bangs',
            "Too many '!' for relative task in this context.",
            @property) if id[0] == ?!
      if task
        task.fullId + '.' + id
      else
        id
      end
    })
  end

  def rule_taskDepList
    newRule('taskDepList')
    newPattern(%w( !taskDep !moreDepTasks ), Proc.new {
      [ @val[0] ] + @val[1]
    })
  end

  def rule_taskHeader
    newRule('taskHeader')
    newPattern(%w( _task $ID $STRING ), Proc.new {
      @property = Task.new(@project, @val[1], @val[2], @property)
      @property.sourceFileInfo = @scanner.sourceFileInfo
      @property.inheritAttributes
      @scenarioIdx = 0
    })
    arg(1, 'id', 'The ID of the task')
    arg(2, 'name', 'The name of the task')
  end

  def rule_taskId
    newRule('taskId')
    newPattern(%w( !taskIdUnverifd ), Proc.new {
      if (task = @project.task(@val[0])).nil?
        error('unknown_task', "Unknown task #{@val[0]}")
      end
      task
    })
  end

  def rule_taskIdUnverifd
    newRule('taskIdUnverifd')
    singlePattern('$ABSOLUTE_ID')
    singlePattern('$ID')
  end

  def rule_taskPred
    newRule('taskPred')
    newPattern(%w( !taskPredHeader !taskDepBody ), Proc.new {
      @val[0]
    })
  end

  def rule_taskPredHeader
    newRule('taskPredHeader')
    newPattern(%w( !taskDepId ), Proc.new {
      @taskDependency = TaskDependency.new(@val[0], false)
    })
  end

  def rule_taskPredList
    newRule('taskPredList')
    newPattern(%w( !taskPred !morePredTasks ), Proc.new {
      [ @val[0] ] + @val[1]
    })
  end

  def rule_taskScenarioAttributes
    newRule('taskScenarioAttributes')

    newPattern(%w( _allocate !resourceAllocations ), Proc.new {
      # Don't use << operator here so the 'provided' flag gets set properly.
      @property['allocate', @scenarioIdx] =
        @property['allocate', @scenarioIdx] + @val[1]
    })
    doc('allocate', <<'EOT'
Specify which resources should be allocated to the task. The optional
attributes provide numerous ways to control which resource is used and when
exactly it will be assigned to the task. Shifts and limits can be used to
restrict the allocation to certain time intervals or to limit them to a
certain maximum per time period.
EOT
       )

    newPattern(%w( _booking !taskBooking ))
    doc('task.booking', <<'EOT'
Bookings can be used to report already completed work by specifying the exact
time intervals a certain resource has worked on this task.
EOT
       )

    newPattern(%w( _complete !number), Proc.new {
      if @val[1] < 0.0 || @val[1] > 100.0
        error('task_complete', "Complete value must be between 0 and 100",
              @property)
      end
      @property['complete', @scenarioIdx] = @val[1]
    })
    doc('complete', <<'EOT'
Specifies what percentage of the task is already completed. This can be useful
for project tracking. Reports with calendar elements may show the completed
part of the task in a different color. The completion percentage has no impact
on the scheduler. It's meant for documentation purposes only.
Tasks may not have subtasks if this attribute is used.
EOT
        )
    arg(1, 'percent', 'The percent value. It must be between 0 and 100.')

    newPattern(%w( _depends !taskDepList ), Proc.new {
      @property['depends', @scenarioIdx] =
        @property['depends', @scenarioIdx] + @val[1]
      @property['forward', @scenarioIdx] = true
    })
    doc('depends', <<'EOT'
Specifies that the task cannot start before the specified tasks have been
finished.

By using the 'depends' attribute, the scheduling policy is automatically set
to asap. If both depends and precedes are used, the last policy counts.
EOT
        )

    newPattern(%w( _duration !calendarDuration ), Proc.new {
      @property['duration', @scenarioIdx] = @val[1]
    })
    doc('duration', <<'EOT'
Specifies the time the task occupies the resources. This is calendar time, not
working time. 7d means one week. If resources are specified they are allocated
when available. Availability of resources has no impact on the duration of the
task. It will always be the specified duration.

Tasks may not have subtasks if this attribute is used.
EOT
       )
    also(%w( effort length ))

    newPattern(%w( _effort !workingDuration ), Proc.new {
      if @val[1] <= 0.0
        error('effort_zero', "Effort value must be larger than 0", @property)
      end
      @property['effort', @scenarioIdx] = @val[1]
    })
    doc('effort', <<'EOT'
Specifies the effort needed to complete the task. An effort of 4d can be done
with 2 full-time resources in 2 days. The task will not finish before the
resources have contributed the specified effort. So the duration of the task
will depend on the availability of the resources.

WARNING: In almost all real world projects effort is not the product of time
and resources. This is only true if the task can be partitioned without adding
any overhead. For more information about this read "The Mythical Man-Month" by
Frederick P. Brooks, Jr.

Tasks may not have subtasks if this attribute is used.
EOT
       )
    also(%w( duration length ))

    newPattern(%w( _end !valDate ), Proc.new {
      @property['end', @scenarioIdx] = @val[1]
      @property['forward', @scenarioIdx] = false
    })
    doc('end', <<'EOT'
The end date of the task. When specified for the top-level (default) scenario
this attributes also implicitly sets the scheduling policy of the tasks to
alap.
EOT
       )

    newPattern(%w( _flags !flagList ), Proc.new {
      @property['flags', @scenarioIdx] += @val[1]
    })
    doc('task.flags', <<'EOT'
Attach a set of flags. The flags can be used in logical expressions to filter
properties from the reports.
EOT
       )

    newPattern(%w( _length !workingDuration ), Proc.new {
      @property['length', @scenarioIdx] = @val[1]
    })
    doc('length', <<'EOT'
Specifies the time the task occupies the resources. This is working time, not
calendar time. 7d means 7 working days, not one week. Whether a day is
considered a working day or not depends on the defined working hours and
global vacations. A task with a length specification may have resource
allocations. Resources are allocated when they are available. The availability
has no impact on the duration of the task. A day where none of the specified
resources is available is still considered a working day, if there is no
global vacation or global working time defined.

Tasks may not have subtasks if this attribute is used.
EOT
       )
    also(%w( duration effort ))

    newPattern(%w( _maxend !valDate ), Proc.new {
      @property['maxend', @scenarioIdx] = @val[1]
    })
    doc('maxend', <<'EOT'
Specifies the maximum wanted end time of the task. The value is not used
during scheduling, but is checked after all tasks have been scheduled. If the
end of the task is later than the specified value, then an error is reported.
EOT
       )

    newPattern(%w( _maxstart !valDate ), Proc.new {
      @property['maxstart', @scenarioIdx] = @val[1]
    })
    doc('maxstart', <<'EOT'
Specifies the maximum wanted start time of the task. The value is not used
during scheduling, but is checked after all tasks have been scheduled. If the
start of the task is later than the specified value, then an error is
reported.
EOT
       )

    newPattern(%w( _milestone ), Proc.new {
      @property['milestone', @scenarioIdx] = true
    })
    doc('milestone', <<'EOT'
Turns the task into a special task that has no duration. You may not specify a
duration, length, effort or subtasks for a milestone task.

A task that only has a start or an end specification and no duration
specification or sub tasks, will be recognized as milestone automatically.
EOT
       )

    newPattern(%w( _minend !valDate ), Proc.new {
      @property['minend', @scenarioIdx] = @val[1]
    })
    doc('minend', <<'EOT'
Specifies the minimum wanted end time of the task. The value is not used
during scheduling, but is checked after all tasks have been scheduled. If the
end of the task is earlier than the specified value, then an error is
reported.
EOT
       )

    newPattern(%w( _minstart !valDate ), Proc.new {
      @property['minstart', @scenarioIdx] = @val[1]
    })
    doc('minstart', <<'EOT'
Specifies the minimum wanted start time of the task. The value is not used
during scheduling, but is checked after all tasks have been scheduled. If the
start of the task is earlier than the specified value, then an error is
reported.
EOT
       )

    newPattern(%w( !period ))

    newPattern(%w( _precedes !taskPredList ), Proc.new {
      @property['precedes', @scenarioIdx] =
        @property['precedes', @scenarioIdx] + @val[1]
      @property['forward', @scenarioIdx] = false
    })
    doc('precedes', <<'EOT'
Specifies that the tasks with the specified IDs cannot start before the task
has been finished. If multiple IDs are specified, they must be separated by
commas. IDs must be either global or relative. A relative ID starts with a
number of '!'. Each '!' moves the scope to the parent task. Global IDs do not
contain '!', but have IDs separated by dots.

By using the 'precedes' attribute, the scheduling policy is automatically set
to alap. If both depends and precedes are used within a task, the last policy
counts.
EOT
       )

    newPattern(%w( _priority $INTEGER ), Proc.new {
      if @val[1] < 0 || @val[1] > 1000
        error('task_priority', "Priority must have a value between 0 and 1000",
              @property)
      end
    })
    doc('priorty', <<'EOT'
Specifies the priority of the task. A task with higher priority is more
likely to get the requested resources. The default priority value of all tasks
is 500. Don't confuse the priority of a tasks with the importance or urgency
of a task. It only increases the chances that the tasks gets the requested
resources. It does not mean that the task happens earlier, though that is
usually the effect you will see. It also does not have any effect on tasks
that don't have any resources assigned (e.g. milestones).

This attribute is inherited by subtasks if specified prior to the definition
of the subtask.
EOT
       )
    arg(1, 'value', 'Priority value (1 - 1000)')

    newPattern(%w( _responsible !resourceList ), Proc.new {
      @property['responsible', @scenarioIdx] = @val[1]
    })
    doc('responsible', <<'EOT'
The ID of the resource that is responsible for this task. This value is for
documentation purposes only. It's not used by the scheduler.
EOT
       )

    newPattern(%w( _scheduled ), Proc.new {
      @property['scheduled', @scenarioIdx] = true
    })
    doc('scheduled', <<'EOT'
This is mostly for internal use. It specifies that the task can be ignored for
scheduling in the scenario.
EOT
       )

    newPattern(%w( _scheduling !schedulingDirection ), Proc.new {
      if @val[1] == 'alap'
        @property['forward', @scenarioIdx] = false
      elsif @val[1] == 'asap'
        @property['forward', @scenarioIdx] = true
      end
    })
    doc('scheduling', <<'EOT'
Specifies the scheduling policy for the task. A task can be scheduled from
start to end (As Soon As Possible, asap) or from end to start (As Late As
Possible, alap).

A task can be scheduled from start to end (ASAP mode) when it has a hard
(start) or soft (depends) criteria for the start time. A task can be scheduled
from end to start (ALAP mode) when it has a hard (end) or soft (precedes)
criteria for the end time.

Some task attributes set the scheduling policy implicitly. This attribute can
be used to explicitly set the scheduling policy of the task to a certain
direction. To avoid it being overwritten again by an implicit attribute this
attribute should always be the last attribute of the task.

A random mixture of ASAP and ALAP tasks can have unexpected side effects on
the scheduling of the project. It increases significantly the scheduling
complexity and results in much longer scheduling times. Especially in projects
with many hundreds of tasks the scheduling time of a project with a mixture of
ASAP and ALAP times can be 2 to 10 times longer. When the projects contains
chains of ALAP and ASAP tasks the tasks further down the dependency chain will
be served much later than other non-chained task even when they have a much
higher priority. This can result in situations where high priority tasks do
not get their resources even though the parallel competing tasks have a much
lower priority.

As a general rule, try to avoid ALAP tasks whenever possible. Have a close
eye on tasks that have been switched implicitly to ALAP mode because the
end attribute comes after the start attribute.
EOT
       )
    arg(1, 'policy', 'Possible values are asap or alap')

    newPattern(%w( _start !valDate), Proc.new {
      @property['start', @scenarioIdx] = @val[1]
      @property['forward', @scenarioIdx] = true
    })
    doc('start', <<'EOT'
The start date of the task. When specified for the top-level (default)
scenario this attribute also implicitly sets the scheduling policy of the task
to asap.
EOT
       )
    also(%w( end period maxstart minstart scheduling ))
    # Other attributes will be added automatically.
  end

  def rule_timeInterval
    newRule('timeInterval')
    newPattern([ '$TIME', '_ - ', '$TIME' ], Proc.new {
      if @val[0] >= @val[2]
        error('time_interval',
              "End time of interval must be larger than start time")
      end
      [ @val[0], @val[2] ]
    })
  end

  def rule_timezone
    newRule('timezone')
    newPattern(%w( _timezone $STRING ))
    doc('timezone', <<'EOT'
Sets the default timezone of the project. All times that have no time
zones specified will be assumed to be in this timezone. The value must
be a string just like those used for the TZ environment variable. Most
Linux systems have a command line utility called tzselect to lookup
possible values.

The project start and end time are not affected by this setting. You
have to explicitly state the timezone for those dates or the system
defaults are assumed.
EOT
        )
    arg(1, 'zone', 'Time zone to use. E. g. Europe/Berlin')
  end

  def rule_vacationName
    newRule('vacationName')
    optional
    newPattern(%w( $STRING )) # We just throw the name away
    arg(0, 'name', 'An optional name for the vacation')
  end

  def rule_valDate
    newRule('valDate')
    newPattern(%w( $DATE ), Proc.new {
      if @val[0] < @project['start'] || @val[0] > @project['end']
        error('date_in_range', "Date must be within the project time frame " +
              "#{@project['start']} +  - #{@project['end']}")
      end
      @val[0]
    })
  end

  def rule_valInterval
    newRule('valInterval')
    newPattern(%w( $DATE !intervalEnd ), Proc.new {
      mode = @val[1][0]
      endSpec = @val[1][1]
      if mode == 0
        iv = Interval.new(@val[0], endSpec)
      else
        iv = Interval.new(@val[0], @val[0] + endSpec)
      end
      # Make sure the interval is within the project time frame.
      if iv.start < @project['start'] || iv.start >= @project['end']
        error('interval_start_in_range',
              "Start date #{iv.start} must be within the project time frame")
      end
      if iv.end <= @project['start'] || iv.end > @project['end']
        error('interval_end_in_range',
              "End date #{iv.end} must be within the project time frame")
      end
      iv
    })
  end

  def rule_weekday
    newRule('weekday')
    newPattern(%w( _sun ), Proc.new { 0 })
    newPattern(%w( _mon ), Proc.new { 1 })
    newPattern(%w( _tue ), Proc.new { 2 })
    newPattern(%w( _wed ), Proc.new { 3 })
    newPattern(%w( _thu ), Proc.new { 4 })
    newPattern(%w( _fri ), Proc.new { 5 })
    newPattern(%w( _sat ), Proc.new { 6 })
  end

  def rule_weekDayInterval
    newRule('weekDayInterval')
    newPattern(%w( !weekday !weekDayIntervalEnd ), Proc.new {
      weekdays = Array.new(7, false)
      if @val[1].nil?
        weekdays[@val[0]] = true
      else
        first = @val[0]
        last = @val[1]
        first.upto(last + 7) { |i| weekdays[i % 7] = true }
      end

      weekdays
    })
    arg(0, 'weekday', 'Weekday (sun - sat)')
  end

  def rule_weekDayIntervalEnd
    newRule('weekDayIntervalEnd')
    optional
    newPattern([ '_ - ', '!weekday' ], Proc.new {
      @val[1]
    })
    arg(1, 'end weekday',
        'Weekday (sun - sat). It is included in the interval.')
  end

  def rule_workingDuration
    newRule('workingDuration')
    newPattern(%w( !number !durationUnit ), Proc.new {
      convFactors = [ 60, # minutes
                      60 * 60, # hours
                      60 * 60 * @project['dailyworkinghours'], # days
                      60 * 60 * @project['dailyworkinghours'] *
                      (@project['yearlyworkingdays'] / 52.1429), # weeks
                      60 * 60 * @project['dailyworkinghours'] *
                      (@project['yearlyworkingdays'] / 12), # months
                      60 * 60 * @project['dailyworkinghours'] *
                      @project['yearlyworkingdays'] # years
                    ]
      (@val[0] * convFactors[@val[1]] /
       @project['scheduleGranularity']).round.to_i
    })
    arg(0, 'value', 'A floating point or integer number')
  end

  def rule_workinghours
    newRule('workinghours')
    newPattern(%w( _workinghours !listOfDays !listOfTimes), Proc.new {
      wh = @property.nil? ? @project['workinghours'] :
           @property['workinghours', @scenarioIdx]
      0.upto(6) { |i| wh.setWorkingHours(i, @val[2]) if @val[1][i] }
    })
    doc('workinghours', <<'EOT'
The working hours specification limits the availability of resources to
certain time slots of week days.
EOT
       )
  end

end
