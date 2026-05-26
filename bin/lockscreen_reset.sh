#!/bin/bash

LOCK_SCREEN_NUMBER=$0

hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'

# restart lockscreen of choice
hyprctl --instance 0 'dispatch exec hyprlock'
