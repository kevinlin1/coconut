// Clock times as minutes past midnight, with lenient parsing so an instructor
// can write the times the way they would say them.
//
// Accepts "9:30", "09:30", "9:30am", "9:30 AM", "2pm", "14:00", or a plain
// integer count of minutes.
#let parse-time(value) = {
  if type(value) == int { return value }
  assert(type(value) == str, message: "expected a time string, found " + str(type(value)))
  let text = lower(value).replace(" ", "").replace(".", "")
  let pm = text.ends-with("pm")
  let am = text.ends-with("am")
  let digits = text.trim("am", at: end).trim("pm", at: end)
  let parts = digits.split(":")
  assert(
    parts.len() <= 2 and parts.first() != "",
    message: "could not read \"" + value + "\" as a time; try \"9:30am\" or \"14:00\"",
  )
  let hour = int(parts.first())
  let minute = if parts.len() == 2 { int(parts.last()) } else { 0 }
  if pm and hour < 12 { hour += 12 }
  if am and hour == 12 { hour = 0 }
  hour * 60 + minute
}

// `clock` is "12h" or "24h". 12-hour output uses a non-breaking space before
// the meridiem so a time never wraps across lines in a narrow table cell.
#let format-time(minutes, clock: "12h") = {
  let hour = calc.rem(calc.div-euclid(minutes, 60), 24)
  let minute = calc.rem(minutes, 60)
  let mm = if minute < 10 { "0" + str(minute) } else { str(minute) }
  if clock == "24h" {
    (if hour < 10 { "0" + str(hour) } else { str(hour) }) + ":" + mm
  } else {
    let meridiem = if hour < 12 { "a.m." } else { "p.m." }
    let h = calc.rem(hour, 12)
    let h = if h == 0 { 12 } else { h }
    str(h) + ":" + mm + "\u{00A0}" + meridiem
  }
}

#let format-range(start, end, clock: "12h") = {
  format-time(start, clock: clock) + "\u{2013}" + format-time(end, clock: clock)
}
