Feature: I want to be able to start and stop instances on a schedule,
so that instances are only running during the day.

    Scenario Outline: I want to be able to start exisiting stopped instances
        Given there are instances <instances>
        When the instances are turned on
        Then all of the instances should be turned on
        Examples:
        | instances                                             |
        | anInstance                                            |
        | anInstance,aTotallyRealInstance,aNotAtAllFakeInstance |

    Scenario Outline: I want to be able to stop existing running instances
        Given there are instances <instances>
        When the instances are turned off
        Then all of the instances should be turned off
        Examples:
        | instances                                             |
        | anInstance                                            |
        | anInstance,aTotallyRealInstance,aNotAtAllFakeInstance |

    Scenario Outline: I want instances to be started at the specified local time rather then UTC (daylight savings issue)
        Given there are instances <instances>
        And the current hour is <time>
        When the instances are turned on with a time check
        Then the instances <should_or_should_not> be turned on
        Examples:
        | instances                                             | time  | should_or_should_not  |
        | anInstance                                            | 7     | should                |
        | anInstance                                            | 8     | should_not            |
        | anInstance,aTotallyRealInstance,aNotAtAllFakeInstance | 7     | should                |
        | anInstance,aTotallyRealInstance,aNotAtAllFakeInstance | 8     | should_not            |

    Scenario Outline: I want instances to be stopped at the specified local time rather then UTC (daylight savings issue)
        Given there are instances <instances>
        And the current hour is <time>
        When the instances are turned off with a time check
        Then the instances <should_or_should_not> be turned off
        Examples:
        | instances                                             | time  | should_or_should_not  |
        | anInstance                                            | 19    | should                |
        | anInstance                                            | 20    | should_not            |
        | anInstance,aTotallyRealInstance,aNotAtAllFakeInstance | 19    | should                |
        | anInstance,aTotallyRealInstance,aNotAtAllFakeInstance | 20    | should_not            |
