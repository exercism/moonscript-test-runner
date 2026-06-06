leap_year = (year) ->
  -- using c-like boolean operators instead of lua `and` and `or`
  (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0)

return leap_year
