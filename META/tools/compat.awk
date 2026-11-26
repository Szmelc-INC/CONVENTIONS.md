# Parse META/compat/registry.toml (the TOML subset documented in its header) into records
# separated by the ASCII unit separator (\037), for META/tools/build.sh and META/tools/check.sh:
#   D <disclaimer>
#   E <id> <name> <kind> <description> <version> <added> <updated> <icon> <spec paths, space-separated> <homepage> <repo> <docs> <community>
# Grammar errors (unknown or duplicate keys, wrong value types, stray lines) go to stderr; exit 1.
# POSIX awk only (mawk in CI): no interval expressions, no gawk extensions.
BEGIN {
  US = "\037"; sec = "top"; n = 0; bad = 0
  split("id name kind description version icon", a, " "); for (i in a) T["rec." a[i]] = "str"
  T["rec.added"] = "date"; T["rec.updated"] = "date"; T["rec.spec"] = "arr"
  split("homepage repo docs community", a, " "); for (i in a) T["links." a[i]] = "str"
  T["top.disclaimer"] = "str"
  NF_ORDER = "id name kind description version added updated icon spec homepage repo docs community"
}
function die(msg) { printf "%s:%d: %s\n", FILENAME, FNR, msg > "/dev/stderr"; bad = 1 }
function flush(   k, out, i, f) {
  if (!n) return
  out = "E"; split(NF_ORDER, f, " ")
  for (i = 1; i <= 13; i++) { k = f[i]; out = out US V[k] }
  print out
  for (k in V) delete V[k]
}
function str(v) { # "..." without quotes or backslashes inside → content, else sentinel
  if (v !~ /^"[^"\\]*"$/) return "\001"
  return substr(v, 2, length(v) - 2)
}
/^[ \t]*(#.*)?$/ { next }
/^\[\[compat\]\]$/ { flush(); n++; sec = "rec"; links = 0; next }
/^\[compat\.links\]$/ {
  if (sec != "rec" || links) die("[compat.links] must follow its [[compat]] record once")
  sec = "links"; links = 1; next
}
{
  if (!match($0, /^[a-z_]+ = /)) { die("expected 'key = value': " $0); next }
  key = substr($0, 1, RLENGTH - 3); val = substr($0, RLENGTH + 1)
  t = T[sec "." key]
  if (t == "") { die("unknown key '" key "' in " sec); next }
  if (sec == "top") { if (key in TOP) { die("duplicate key '" key "'"); next } }
  else if (key in V) { die("duplicate key '" key "'"); next }
  if (t == "str") {
    s = str(val); if (s == "\001") { die("'" key "' must be a \"string\" without quotes or backslashes"); next }
  } else if (t == "date") {
    if (val !~ /^[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]$/) { die("'" key "' must be a YYYY-MM-DD date"); next }
    s = val
  } else {
    if (val !~ /^\[.*\]$/) { die("'" key "' must be an array of strings"); next }
    inner = substr(val, 2, length(val) - 2); s = ""
    m = split(inner, parts, ", ")
    for (i = 1; i <= m; i++) {
      p = str(parts[i]); if (p == "\001" || p ~ / /) { die("'" key "' items must be \"strings\" without spaces"); s = ""; break }
      s = s (i > 1 ? " " : "") p
    }
  }
  if (sec == "top") { TOP[key] = s; print "D" US s } else V[key] = s
}
END { flush(); if (bad) exit 1; if (!("disclaimer" in TOP)) { print FILENAME ": missing disclaimer" > "/dev/stderr"; exit 1 } }
