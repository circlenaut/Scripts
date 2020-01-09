#!/bin/bash

# Don't run more often that 5 seconds; this is about how long it takes to run the command below
AC_ADAPTER=$(acpi -a | cut -d' ' -f3 | cut -d- -f1)

if [[ "$AC_ADAPTER" == *"on"* ]]; then
    echo "0" > /tmp/discharge-rate.stat
    BAT0_CHARGE_STATE=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "state:" | awk '{print $2}')
    BAT0_CHARGE_PERCENTAGE=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "percentage:" | awk '{print $2}' | tr -dc '0-9')
    BAT0_CHARGE_THRESHOLD=$(tlp-stat -b | grep "/sys/class/power_supply/BAT0/charge_stop_threshold" | awk '{print $3}')

    if [[ "$BAT0_CHARGE_STATE" == *"fully-charged"* ]]; then
        BAT0_CHARGE_TIME_HOURS="0"
    elif [[ "$BAT0_CHARGE_STATE" == *"charging"* ]]; then
        if (( $(echo "$BAT0_CHARGE_PERCENTAGE >= $BAT0_CHARGE_THRESHOLD" | bc -l) )); then
            BAT0_CHARGE_TIME_HOURS="0"
        elif (( $(echo "$BAT0_CHARGE_PERCENTAGE < $BAT0_CHARGE_THRESHOLD" | bc -l) )); then
            BAT0_CHARGE_TIME_UNIT=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to full:" | awk '{print $5}')
            if [[ "$BAT0_CHARGE_TIME_UNIT" == *"hours"* ]]; then
                BAT0_CHARGE_TIME_HOURS=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to full:" | awk '{print $4}')
            elif [[ "$BAT0_CHARGE_TIME_UNIT" == *"minutes"* ]]; then
                BAT0_CHARGE_TIME_MINS=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to full:" | awk '{print $4}')
                BAT0_CHARGE_TIME_HOURS=$(echo "scale=2; $BAT0_CHARGE_TIME_MINS  / 100" | bc)
            else
                BAT0_CHARGE_TIME_HOURS="Error"
            fi
        else
            BAT0_CHARGE_TIME_HOURS="Error"
        fi
    else
        BAT0_CHARGE_TIME_HOURS="Error"
    fi

    BAT1_CHARGE_STATE=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "state:" | awk '{print $2}')
    BAT1_CHARGE_PERCENTAGE=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "percentage:" | awk '{print $2}' | tr -dc '0-9')
    BAT1_CHARGE_THRESHOLD=$(tlp-stat -b | grep "/sys/class/power_supply/BAT1/charge_stop_threshold" | awk '{print $3}')

    if [[ "$BAT1_CHARGE_STATE" == *"fully-charged"* ]]; then
        BAT1_CHARGE_TIME_HOURS="0"
    elif [[ "$BAT1_CHARGE_STATE" == *"charging"* ]]; then
        if (( $(echo "$BAT1_CHARGE_PERCENTAGE >= $BAT1_CHARGE_THRESHOLD" | bc -l) )); then
            BAT1_CHARGE_TIME_HOURS="0"
        elif (( $(echo "$BAT1_CHARGE_PERCENTAGE < $BAT1_CHARGE_THRESHOLD" | bc -l) )); then
            BAT1_CHARGE_TIME_UNIT=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "time to full:" | awk '{print $5}')
            if [[ "$BAT1_CHARGE_TIME_UNIT" == *"hours"* ]]; then
                BAT1_CHARGE_TIME_HOURS=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "time to full:" | awk '{print $4}')
            elif [[ "$BAT1_CHARGE_TIME_UNIT" == *"minutes"* ]]; then
                BAT1_CHARGE_TIME_MINS=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "time to full:" | awk '{print $4}')
                BAT1_CHARGE_TIME_HOURS=$(echo "scale=2; $BAT1_CHARGE_TIME_MINS  / 100" | bc)
            else
                BAT1_CHARGE_TIME_HOURS="Error"
            fi
        else
            BAT1_CHARGE_TIME_HOURS="Error"
        fi
    else
        BAT1_CHARGE_TIME_HOURS="Error"
    fi

    BATTERY_CHARGE_DECIMAL_TIME=$(echo "scale=2; $BAT0_CHARGE_TIME_HOURS + $BAT1_CHARGE_TIME_HOURS" | bc)

    if (( $(echo "$BATTERY_CHARGE_DECIMAL_TIME == 0" | bc -l) )); then
        BATTERY_CHARGE_TIME="0":"00"
    elif (( $(echo "$BATTERY_CHARGE_DECIMAL_TIME > 0" | bc -l) )); then
        BATTERY_CHARGE_TIME_HOURS=$(echo "$BATTERY_CHARGE_DECIMAL_TIME" | awk -F. '{ print ($1)}')
        BATTERY_CHARGE_DECIMAL_TIME_MINS=$(echo "$BATTERY_CHARGE_DECIMAL_TIME" | awk -F. '{ print ($2)}')
        BATTERY_CHARGE_TIME_MINS=$(echo "scale=2; $BATTERY_CHARGE_DECIMAL_TIME_MINS / 100 * 60" | bc | awk -F. '{ print ($1)}')
        if (( $(echo "$BATTERY_CHARGE_TIME_MINS < 10" | bc -l) )); then
            BATTERY_CHARGE_TIME_MINS="0""$BATTERY_CHARGE_TIME_MINS"
        elif (( $(echo "$BATTERY_CHARGE_TIME_MINS >= 10" | bc -l) )); then
            BATTERY_CHARGE_TIME_MINS="$BATTERY_CHARGE_TIME_MINS"
        else
            BATTERY_CHARGE_TIME_MINS="Error"
        fi
        if (( $(echo "$BATTERY_CHARGE_DECIMAL_TIME < 1" | bc -l) )); then
            BATTERY_CHARGE_TIME="0":"$BATTERY_CHARGE_TIME_MINS"
        elif (( $(echo "$BATTERY_CHARGE_DECIMAL_TIME >= 1" | bc -l) )); then
            BATTERY_CHARGE_TIME="$BATTERY_CHARGE_TIME_HOURS":"$BATTERY_CHARGE_TIME_MINS"
        else
            BATTERY_CHARGE_TIME="Error"
        fi
    else
        BATTERY_CHARGE_TIME="Error"
    fi

    echo "$BATTERY_CHARGE_TIME" > /tmp/battery-time.stat

    # Tests
#    echo "BAT0_CHARGE_STATE:$BAT0_CHARGE_STATE"
#    echo "BAT0_CHARGE_PERCENTAGE:$BAT0_CHARGE_PERCENTAGE"
#    echo "BAT0_CHARGE_THRESHOLD:$BAT0_CHARGE_THRESHOLD"
#    echo "BAT0_CHARGE_TIME_HOURS:$BAT0_CHARGE_TIME_HOURS"
#    echo "BAT1_CHARGE_STATE:$BAT1_CHARGE_STATE"
#    echo "BAT1_CHARGE_PERCENTAGE:$BAT1_CHARGE_PERCENTAGE"
#    echo "BAT1_CHARGE_THRESHOLD:$BAT1_CHARGE_THRESHOLD"
#    echo "BAT1_CHARGE_TIME_HOURS:$BAT1_CHARGE_TIME_HOURS"
#    echo "BATTERY_CHARGE_DECIMAL_TIME:$BATTERY_CHARGE_DECIMAL_TIME"
#    echo "BATTERY_CHARGE_TIME:$BATTERY_CHARGE_TIME"

elif [[ "$AC_ADAPTER" == *"off"* ]]; then
    DISCHARGE_RATE=$(powertop --quiet --time=0 --csv=/tmp/data.powertop >/dev/null 2>&1 && cat /tmp/data.powertop | grep 'The battery reports a discharge rate of:  ' | cut -d ' ' -f 9)
    BAT0_ENERGY=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "energy:" | awk '{print $2}')
    BAT1_ENERGY=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "energy:" | awk '{print $2}')
    TOTAL_ENERGY=$(echo "$BAT0_ENERGY + $BAT1_ENERGY" | bc)
    BATTERY_DISCHARGE_DECIMAL_TIME=$(echo "scale=2; $TOTAL_ENERGY / $DISCHARGE_RATE" | bc)
    BATTERY_DISCHARGE_TIME_HOURS=$(echo "$BATTERY_DISCHARGE_DECIMAL_TIME" | awk -F. '{ print ($1)}')
    BATTERY_DISCHARGE_TIME_MINS=$(echo "$BATTERY_DISCHARGE_DECIMAL_TIME" | awk -F. '{ print ($2)}')

    if (( $(echo "$BATTERY_DISCHARGE_DECIMAL_TIME < 1" | bc -l) )); then
        BATTERY_DISCHARGE_TIME="0":$(echo "scale=2; $BATTERY_DISCHARGE_TIME_MINS / 100 * 60" | bc | awk -F. '{ print ($1)}')
    elif (( $(echo "$BATTERY_DISCHARGE_DECIMAL_TIME >= 1" | bc -l) )); then
        BATTERY_DISCHARGE_TIME=$BATTERY_DISCHARGE_TIME_HOURS:$(echo "scale=2; $BATTERY_DISCHARGE_TIME_MINS / 100 * 60" | bc | awk -F. '{ print ($1)}')
    else
        BATTERY_DISCHARGE_TIME="Error"
    fi

    echo "$DISCHARGE_RATE" > /tmp/discharge-rate.stat
    echo "$BATTERY_DISCHARGE_TIME" > /tmp/battery-time.stat

    # Tests
#    echo "AC_ADAPTER:$AC_ADAPTER"
#    echo "DISCHARGE_RATE:$DISCHARGE_RATE"
#    echo "BAT0_ENERGY:$BAT0_ENERGY"
#    echo "BAT1_ENERGY:$BAT1_ENERGY"
#    echo "TOTAL_ENERGY:$TOTAL_ENERGY"
#    echo "BATTERY_DISCHARGE_DECIMAL_TIME:$BATTERY_DISCHARGE_DECIMAL_TIME"
#    echo "BATTERY_DISCHARGE_TIME:$BATTERY_DISCHARGE_TIME"
else
    echo "Error" > /tmp/battery-rate.stat
fi