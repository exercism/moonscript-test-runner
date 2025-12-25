leap_year = (number) ->
  is_divisible_by = (a_number) ->
    number % a_number == 0

  is_divisible_by(400) or (is_divisible_by(4) and (not is_divisible_by(100)))

leap_year
